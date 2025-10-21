{
  description = "NixOS configuration for Framework laptop";

  # Inputs are the dependencies of this flake
  # Think of them as "imports" from other repositories
  inputs = {
    # nixpkgs is the main package repository for NixOS
    # We use the unstable channel to get the latest packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager allows us to manage user configurations and dotfiles
    # declaratively using Nix. It's perfect for managing per-user settings.
    home-manager = {
      url = "github:nix-community/home-manager";
      # This ensures home-manager uses the same nixpkgs version as our system
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri is a scrollable-tiling Wayland compositor
    # We include it from a specialized repository
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Outputs are what this flake produces
  # The main output is our NixOS system configuration
  outputs = { self, nixpkgs, home-manager, niri, ... }@inputs:
    let
      # Define the system architecture we're building for
      system = "x86_64-linux";

      # pkgs gives us access to all packages in nixpkgs
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # nixosConfigurations defines our system configurations
      # "framework" is the hostname - you can change this during installation
      nixosConfigurations.framework = nixpkgs.lib.nixosSystem {
        inherit system;

        # Special arguments passed to all NixOS modules
        specialArgs = { inherit inputs; };

        # Modules are the building blocks of NixOS configuration
        # They define how your system should be set up
        modules = [
          # Hardware-specific configuration (partitions, bootloader, etc.)
          ./hardware-configuration.nix

          # Main system configuration
          ./configuration.nix

          # Enable niri compositor
          niri.nixosModules.niri

          # Home Manager as a NixOS module
          # This integrates user configurations with the system config
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # User configuration is in a separate file
            home-manager.users.edgar = import ./home.nix;

            # Pass inputs to home-manager modules
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
}
