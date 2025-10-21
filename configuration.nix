# Main system configuration file
# This defines system-wide settings, services, and packages
# User-specific configurations are in home.nix (managed by Home Manager)

{ config, pkgs, inputs, ... }:

{
  # Set your hostname (the name of your computer on the network)
  networking.hostName = "framework";

  # Set your time zone
  time.timeZone = "Europe/Amsterdam";  # Adjust to your timezone

  # Internationalization settings
  i18n.defaultLocale = "en_US.UTF-8";
  # Additional locale settings
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the niri Wayland compositor
  programs.niri = {
    enable = true;
    # niri is a scrollable-tiling compositor - windows tile automatically
    # but you can scroll through workspaces smoothly
  };

  # Wayland-specific settings
  # XDG portal is needed for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Sound configuration using PipeWire
  # PipeWire is the modern audio/video server for Linux
  security.rtkit.enable = true;  # RealtimeKit for low-latency audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # PulseAudio compatibility
    jack.enable = true;   # JACK compatibility
  };

  # Enable greetd as display manager (login screen)
  # greetd is a minimal, flexible login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # tuigreet provides a nice terminal UI for login
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # swaylock for screen locking
  # This allows non-root users to lock the screen
  security.pam.services.swaylock = {};

  # Enable NetworkManager for easy network management
  networking.networkmanager.enable = true;

  # Define user account
  users.users.edgar = {
    isNormalUser = true;
    description = "Edgar Post-Buijs";
    # Add user to important groups:
    # - wheel: allows using sudo
    # - networkmanager: manage network connections
    # - video: access video devices
    # - audio: access audio devices
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];

    # Set default shell to fish
    shell = pkgs.fish;

    # Initial password - IMPORTANT: Change this after first login!
    # After first login, run: passwd
    # Or set initialHashedPassword instead (see README for how to generate)
    initialPassword = "changeme";

    # SSH authorized keys
    # You can add your public SSH keys here
    # Generate with: ssh-keygen -t ed25519 -C "your_email@example.com"
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here, one per line:
      # "ssh-ed25519 AAAAC3... your_email@example.com"
    ];
  };

  # Enable fish shell system-wide
  # This makes fish available as a login shell
  programs.fish.enable = true;

  # System-wide packages
  # These are available to all users
  environment.systemPackages = with pkgs; [
    # Essential tools
    git              # Version control
    vim              # Text editor (fallback)
    wget             # Download files
    curl             # Transfer data with URLs

    # Wayland utilities
    wl-clipboard     # Clipboard for Wayland
    wayland-utils    # Wayland debugging tools

    # Lock screen
    swaylock         # Screen locker for Wayland

    # For accessing hardware info
    pciutils         # lspci command
    usbutils         # lsusb command

    # Firmware updates
    fwupd            # Firmware updater (important for Framework!)
  ];

  # SSH server configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Allow password login
      PermitRootLogin = "no";         # Don't allow root login
    };
  };

  # Enable automatic garbage collection
  # This removes old system generations to save disk space
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable flakes and new nix command
  # Flakes are the modern way to manage Nix configurations
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages (like Slack)
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release with which your system is
  # to be compatible. Don't change this!
  system.stateVersion = "24.05";
}
