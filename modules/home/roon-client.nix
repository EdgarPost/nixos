# ============================================================================
# ROON CLIENT (Wine) - Desktop GUI for Roon
# ============================================================================
#
# Roon Labs ships no native Linux GUI, so we run the official Windows client
# under Wine. Audio routes through PipeWire transparently.
#
# Commands:
#   roon-gui      Launch the Roon GUI (prints install hint on first run)
#   roon-install  Download + run RoonInstaller64.exe in the Wine prefix
#
# Note: `roon` is taken by the roon-cli flake input (terminal control client).
#
# Wine prefix lives at ~/.roon-wine (outside the Nix store).
# ============================================================================

{ pkgs, lib, config, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";

  roonInstallerUrl = "https://download.roonlabs.com/builds/RoonInstaller64.exe";

  roon = pkgs.writeShellScriptBin "roon-gui" ''
    export WINEPREFIX="$HOME/.roon-wine"
    export WINEARCH=win64
    export WINEDEBUG=-all
    export PATH="${pkgs.wineWow64Packages.stable}/bin:$PATH"

    roon_exe="$WINEPREFIX/drive_c/users/$USER/AppData/Local/Roon/Application/Roon.exe"

    if [ ! -f "$roon_exe" ]; then
      cat >&2 <<EOF
    Roon is not installed in the Wine prefix yet.

    Run:   roon-install

    That downloads RoonInstaller64.exe and runs it under Wine.
    After the installer finishes, run 'roon-gui' again.
    EOF
      exit 1
    fi

    exec wine "$roon_exe" "$@"
  '';

  roon-install = pkgs.writeShellScriptBin "roon-install" ''
    set -euo pipefail
    export WINEPREFIX="$HOME/.roon-wine"
    export WINEARCH=win64
    export WINEDEBUG=-all
    export PATH="${pkgs.wineWow64Packages.stable}/bin:$PATH"

    installer="$WINEPREFIX/RoonInstaller64.exe"
    mkdir -p "$WINEPREFIX"

    if [ ! -f "$installer" ]; then
      echo "Downloading Roon installer..."
      ${pkgs.curl}/bin/curl -fL -o "$installer" "${roonInstallerUrl}"
    fi

    echo "Running Roon installer under Wine..."
    exec wine "$installer"
  '';
in
lib.mkIf isX86 {
  home.packages = [
    pkgs.wineWow64Packages.stable
    pkgs.winetricks
    roon
    roon-install
  ];

  home.activation.createRoonWinePrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.roon-wine" ]; then
      export WINEPREFIX="$HOME/.roon-wine"
      export WINEARCH=win64
      export WINEDEBUG=-all
      ${pkgs.wineWow64Packages.stable}/bin/wineboot --init >/dev/null 2>&1 || true
    fi
  '';

  xdg.desktopEntries.roon = {
    name = "Roon";
    comment = "Roon music player (via Wine)";
    exec = "roon-gui";
    terminal = false;
    categories = [ "Audio" "AudioVideo" ];
    icon = "audio-x-generic";
  };

  # Wine draws Roon with an ARGB buffer, so Hyprland honors the per-pixel
  # alpha and the window renders translucent. force_rgbx strips the alpha
  # channel entirely; `opaque` alone only affects blending and doesn't help.
  wayland.windowManager.hyprland.settings.windowrule = [
    "force_rgbx on, match:class ^(roon\\.exe)$"
  ];
}
