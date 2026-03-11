# ============================================================================
# DESKTOP SYSTEM CONFIGURATION - Opt-in for Graphical Hosts
# ============================================================================
#
# System-level services needed for a desktop environment.
# Import this in host configs that need a GUI (not on headless servers).
#
# Provides:
#   - 1Password GUI with polkit integration
#   - Hyprland compositor (system-level: portals, fonts, packages)
#   - greetd login manager with tuigreet
#   - Podman container runtime
#   - PipeWire audio stack (ALSA, PulseAudio compatibility)
#   - Desktop user groups (video, audio, pipewire)
#
# ============================================================================

{ user, ... }:

{
  imports = [
    ../../modules/nixos/1password-gui.nix   # GUI + polkit
    ../../modules/nixos/hyprland.nix        # Desktop compositor
    ../../modules/nixos/greetd.nix          # Login manager
    ../../modules/nixos/keyd.nix            # Caps Lock → Hyper key
    ../../modules/nixos/podman.nix          # Container runtime
  ];

  # PipeWire audio stack
  # rtkit: Real-time scheduling for audio (prevents glitches)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # PulseAudio compatibility layer
  };

  # Desktop-specific user groups
  # video: screen brightness control (backlight device access)
  # audio: direct audio device access
  # pipewire: system-wide PipeWire audio access
  users.users.${user.name}.extraGroups = [ "video" "audio" "pipewire" "keyd" ];
}
