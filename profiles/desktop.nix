# ============================================================================
# DESKTOP PROFILE - GUI/Wayland Environment
# ============================================================================
#
# Everything needed for a graphical desktop:
#   - Hyprland window manager + keybindings + rofi + hyprlock
#   - Ghostty terminal emulator
#   - Waybar status bar
#   - SwayNC notification center
#   - Audio profile switching (headset, meeting, mobile, analog)
#   - Tmux project picker (Super+P)
#   - MonoLisa font, macOS cursor theme
#   - Desktop apps: Zen Browser, Signal, Slack, Teams, Postman, Thunderbird, Figma, Morgen
#
# This profile is independent - it does not import other profiles.
#
# ============================================================================

{ pkgs, lib, inputs, ... }:

let
  # Shared font configuration - used by terminal, waybar, etc.
  font = {
    family = "MonoLisa";
    size = 14;
  };
in
{
  # Make font available to all imported modules
  _module.args.font = font;

  imports = [
    ../modules/home/hyprland.nix   # Window manager + keybindings
    ../modules/home/ghostty.nix    # Terminal emulator
    ../modules/home/waybar.nix     # Status bar
    ../modules/home/swaync.nix     # Notification center
    ../modules/home/zathura.nix    # PDF viewer
    ../modules/home/audio.nix      # Audio profile switching
    ../modules/home/handy.nix      # Offline speech-to-text
    ../modules/home/thunderbird.nix # Email, calendar & contacts client
  ];

  # ==========================================================================
  # DESKTOP PACKAGES
  # ==========================================================================
  # GUI applications and Wayland utilities
  #
  # SYNTAX PATTERNS:
  #   `inputs.flake.packages.${system}.name` - Package from a flake input
  #   `lib.optionals condition [ list ]` - Conditional list items
  #   `stdenv.hostPlatform.system` - Current architecture string
  home.packages =
    with pkgs;
    [
      impala          # WiFi management TUI
      signal-desktop  # Encrypted messaging
      libreoffice     # Office suite (Word/Excel/PowerPoint)

      # Browser from flake input
      # ${stdenv.hostPlatform.system} resolves to "x86_64-linux" or "aarch64-linux"
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
      figma-linux      # Unofficial Figma desktop client
      # Morgen: use bundled Electron — system Electron 41 causes GPU/window issues
      (morgen.overrideAttrs (old: {
        installPhase = old.installPhase + ''
          rm $out/bin/morgen
          cat > $out/bin/morgen <<EOF
#!/bin/sh
exec $out/opt/Morgen/morgen \''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer --enable-wayland-ime=true}} "\$@"
EOF
          chmod +x $out/bin/morgen
        '';
      }))
      slack            # Only available for x86_64 (no aarch64 build)
      teams-for-linux  # Microsoft Teams client (community Electron wrapper)
      postman          # API testing and development tool
    ];

  # ==========================================================================
  # MICROSOFT TEAMS CONFIGURATION
  # ==========================================================================
  # Spoof user agent to get full functionality (Microsoft limits Linux clients)
  xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON {
    chromeUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/msteams" = "teams-for-linux.desktop";
    };
  };

  # ==========================================================================
  # CURSOR THEME
  # ==========================================================================
  # Consistent cursor across all applications (X11, Wayland, GTK, Qt)
  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;  # macOS-style cursor for Linux
    size = 24;
    gtk.enable = true;  # Apply to GTK applications too
  };

  # ==========================================================================
  # FONT INSTALLATION
  # ==========================================================================
  # MonoLisa: proprietary font, synced via Syncthing to ~/Resources
  home.activation.installMonoLisa = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FONT_SRC="$HOME/Resources/Fonts/MonoLisa-Plus-stable/ttf"
    FONT_DST="$HOME/.local/share/fonts/MonoLisa"
    if [ -d "$FONT_SRC" ]; then
      mkdir -p "$FONT_DST"
      cp -u "$FONT_SRC"/*.ttf "$FONT_DST/"
      ${pkgs.fontconfig}/bin/fc-cache -f "$FONT_DST"
    fi
  '';
}
