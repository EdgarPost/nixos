{
  description = "Edgar's NixOS configuration";

  inputs = {
    # Core
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware profiles
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Zen browser (from NixOS wiki)
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets: using 1Password instead of SOPS
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Catppuccin theming
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, zen-browser, ... }@inputs:
    let
      # ========== User Configuration ==========
      user = {
        name = "edgar";
        fullName = "Edgar Post-Buijs";
        email = "github@edgarpost.com";
      };

      # Helper function to create NixOS system
      mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs user; };
          modules = [
            # Host-specific configuration
            ./hosts/${hostname}

            # Home Manager as NixOS module
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user.name} = {
                imports = [
                  inputs.catppuccin.homeModules.catppuccin
                  ./home
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs user; };
            }

          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        # UTM VM for testing (ARM on M1 Mac)
        utm-vm = mkSystem {
          hostname = "utm-vm";
          system = "aarch64-linux";
        };

        # Framework laptop 12" 12th gen Intel
        framework = mkSystem {
          hostname = "framework";
          system = "x86_64-linux";
        };
      };
    };
}
