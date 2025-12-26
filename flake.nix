# ============================================================================
# FLAKE.NIX - The Entry Point for Your NixOS Configuration
# ============================================================================
#
# WHAT IS A FLAKE?
# A flake is Nix's modern way to define reproducible, hermetic builds.
# Think of it like package.json + package-lock.json combined:
#   - `inputs` = dependencies (like package.json dependencies)
#   - `flake.lock` = exact pinned versions (like package-lock.json)
#   - `outputs` = what this flake produces (your system configs)
#
# WHY FLAKES?
# Before flakes, Nix configs used channels (like apt sources) that could
# change over time. Flakes pin exact git commits, so `flake.lock` guarantees
# the same system on any machine, at any time.
#
# REBUILDING YOUR SYSTEM:
#   sudo nixos-rebuild switch --flake .#framework-laptop   # Apply config
#   sudo nixos-rebuild test --flake .#framework-laptop     # Test without making default
#   sudo nixos-rebuild boot --flake .#framework-laptop     # Apply on next boot
#   nix flake update                                # Update all inputs (like npm update)
#   nix flake lock --update-input nixpkgs           # Update just nixpkgs
#
# ============================================================================
{
  description = "Edgar's NixOS configuration";

  # ==========================================================================
  # INPUTS - External Dependencies
  # ==========================================================================
  # Each input is a flake (git repo) that provides packages, modules, or libs.
  # The `follows` directive ensures all inputs use the same nixpkgs version,
  # preventing version conflicts (similar to npm peer dependencies).

  inputs = {
    # The main package repository - contains 100,000+ packages
    # "nixos-unstable" = rolling release, latest packages (like Arch)
    # Use "nixos-24.11" for stable, slower-updating packages (like Debian)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager: Manages user-level dotfiles and programs declaratively
    # Separate from NixOS (system-level) because:
    #   1. Users shouldn't need sudo to change their shell config
    #   2. Allows per-user package isolation
    #   3. Can be used on non-NixOS systems (macOS, other Linux)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use our nixpkgs, not its own
    };

    # Hardware-specific optimizations for common devices
    # Provides pre-configured modules: power management, firmware, drivers
    # See: github.com/NixOS/nixos-hardware for supported hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Third-party flakes for packages not in nixpkgs
    # The pattern: find a flake on GitHub, add it here, use in config
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management alternative (commented out, using 1Password instead)
    # SOPS-nix encrypts secrets in git, decrypts at build time
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Unified theming across applications
    # One config → consistent colors in terminal, editor, status bar, etc.
    catppuccin.url = "github:catppuccin/nix";

    # Roon CLI - control Roon music player from terminal
    roon-cli = {
      url = "github:EdgarPost/roon-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ==========================================================================
  # OUTPUTS - What This Flake Produces
  # ==========================================================================
  # The outputs function receives all resolved inputs and returns an attrset
  # defining what this flake provides. For a NixOS config, the main output is
  # `nixosConfigurations`.
  #
  # SYNTAX NOTES:
  #   { a, b, ... }@inputs  = Destructure args AND capture full set as `inputs`
  #                           Similar to: ({ a, b, ...rest }) in JS, but `inputs`
  #                           is the ENTIRE set including a and b

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      zen-browser,
      roon-cli,
      ...
    }@inputs:

    # LET...IN - Nix's way of defining local variables
    # Everything in `let` is available in `in`, like function-scoped vars
    let
      # ========== User Configuration ==========
      # Centralized user info passed to all modules via specialArgs
      # Change once here → updates everywhere
      user = {
        name = "edgar";
        fullName = "Edgar Post-Buijs";
        email = "info@edgarpost.com";

        git = {
          email = "github@edgarpost.com";
        };
      };

      # ========== Network Hosts ==========
      # Hostnames of other machines on the network (resolved via Tailscale/mDNS)
      hosts = {
        pbstation = "192.168.2.10";  # Synology NAS (Roon Core) - static LAN IP
      };

      # ========== Helper Function ==========
      # DRY: One function to create system configs for any host
      #
      # SYNTAX: { hostname, system ? "x86_64-linux", ... }
      #   - Named arguments (like Python kwargs)
      #   - `?` sets default value
      #   - Explicit args: system, hostname, extraModules
      mkSystem =
        {
          hostname,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          # `inherit system` is shorthand for `system = system;`
          # Common pattern to avoid repetition
          inherit system;

          # SPECIALARGS - How data flows to modules
          # Modules are functions: { config, pkgs, lib, ... }: { ... }
          # specialArgs adds extra args (inputs, user) available in all modules
          # This is THE way to pass custom data through your config
          specialArgs = { inherit inputs user hosts; };

          # MODULES - The composition system
          # Each module is a function that returns an attrset of config
          # NixOS merges all modules together (like Object.assign but smarter)
          # Modules can:
          #   - Set options (config values)
          #   - Define new options (for other modules to set)
          #   - Import other modules
          modules = [
            # Host-specific configuration (hardware, hostname, bootloader)
            # String interpolation: ${hostname} embeds variable in path
            ./hosts/${hostname}

            # Integrate Home Manager as a NixOS module
            # Alternative: standalone home-manager (separate `home-manager switch`)
            # As NixOS module: single `nixos-rebuild switch` updates everything
            home-manager.nixosModules.home-manager
            {
              # Use nixpkgs from NixOS (not Home Manager's own)
              # Ensures same package versions between system and user
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";  # Auto-backup conflicting files

              # Configure this user's home (${user.name} = string interpolation)
              home-manager.users.${user.name} = {
                imports = [
                  # Catppuccin theme module - adds catppuccin.* options
                  inputs.catppuccin.homeModules.catppuccin
                  # Roon CLI - adds services.roon-cli options
                  inputs.roon-cli.homeManagerModules.default
                  # Main home configuration
                  ./home
                ];
              };

              # Pass same custom args to Home Manager modules
              home-manager.extraSpecialArgs = { inherit inputs user hosts; };
            }

            # LIST CONCATENATION: `++` joins two lists
            # Allows mkSystem callers to add host-specific modules
          ]
          ++ extraModules;
        };

      # IN - The actual return value (using vars from `let`)
    in
    {
      # NIXOSCONFIGURAITONS - Named system profiles
      # Build with: nixos-rebuild switch --flake .#<name>
      # Each key is a configuration name (typically matches hostname)
      nixosConfigurations = {
        # UTM VM for testing on Apple Silicon Mac
        # aarch64-linux = ARM64 architecture
        utm-vm = mkSystem {
          hostname = "utm-vm";
          system = "aarch64-linux";
        };

        # Primary machine: Framework laptop
        # x86_64-linux = Intel/AMD 64-bit
        framework-laptop = mkSystem {
          hostname = "framework-laptop";
          system = "x86_64-linux";
        };
      };

      # ========================================================================
      # HOMECONFIGURATIONS - Standalone Home Manager for non-NixOS servers
      # ========================================================================
      # Use on Ubuntu, Debian, or any Linux with Nix installed.
      # Apply with: nix run home-manager/master -- switch --flake .#edgar@server
      #
      # 1PASSWORD: Set OP_SERVICE_ACCOUNT_TOKEN env var for op CLI access
      homeConfigurations = {
        # x86_64 servers (most cloud providers: AWS, GCP, Azure, etc.)
        "edgar@server" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs user hosts; };
          modules = [
            inputs.catppuccin.homeModules.catppuccin
            ./home/server.nix
          ];
        };

        # ARM servers (AWS Graviton, Oracle Cloud free tier, etc.)
        "edgar@server-arm" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs user hosts; };
          modules = [
            inputs.catppuccin.homeModules.catppuccin
            ./home/server.nix
          ];
        };
      };
    };
}
