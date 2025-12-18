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

    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, ... }@inputs:
    let
      # ========== User Configuration ==========
      user = {
        name = "edgar";
        fullName = "Edgar Post-Buijs";
        # email configured via SOPS secrets
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
              home-manager.users.${user.name} = import ./home;
              home-manager.extraSpecialArgs = { inherit inputs user; };
            }

            # SOPS for secrets
            sops-nix.nixosModules.sops
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
