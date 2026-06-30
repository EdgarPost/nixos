# ============================================================================
# SUNSHINE - Game Streaming to Steam Deck (with on-demand virtual display)
# ============================================================================
#
# Sunshine is a self-hosted game-stream host; the Steam Deck connects to it with
# the Moonlight client. Instead of streaming the physical Dell ultrawide, this
# setup creates a dedicated VIRTUAL display at 2560x1440@90 the moment a stream
# starts and removes it when the stream stops:
#
#   stream start (prep "do")   -> create a Hyprland headless output, set it to
#                                 1440p@90, then disable the Dell (DP-4). The
#                                 virtual output becomes the ONLY active display,
#                                 so Sunshine captures the right one and the game
#                                 lands there. The physical desk screen goes dark.
#   stream stop  (prep "undo") -> restore the Dell at its native res/scale and
#                                 remove the headless output.
#
# Two Moonlight apps are exposed, both sharing the display logic:
#   - "Steam Big Picture": additionally auto-launches Steam Big Picture onto the
#     virtual display (the console-like app you pick on the Deck).
#   - "Desktop": same display, no auto-launch (full desktop fallback).
#
# WHY SUNSHINE AND NOT APOLLO?
# Apollo's headline feature (auto virtual display via "SudoVDA") is Windows-only;
# on Linux you script the display exactly like this regardless of fork. So plain
# Sunshine wins: it's in nixpkgs and maintained, no extra flake input.
#
# NOTE: Sunshine runs as a systemd *user* service, and that unit forces PATH to
# null. The prep scripts below are built with writeShellApplication, which bakes
# absolute paths to their runtimeInputs into the script, so they work regardless
# of PATH. The Steam launch likewise uses an absolute path.
# ============================================================================

{
  pkgs,
  lib,
  user,
  inputs,
  ...
}:

let
  # The sunshine package in our main nixpkgs lags the upstream release. Build it
  # from a second nixpkgs pinned just for this package (flake input
  # `nixpkgs-sunshine`), leaving the rest of the system on the main nixpkgs.
  pkgsSunshine = import inputs.nixpkgs-sunshine {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Make hyprctl reachable even if the user service didn't inherit the env var
  # that tells it which running Hyprland instance to talk to. Fall back to the
  # most recent instance socket under $XDG_RUNTIME_DIR/hypr.
  hyprEnv = ''
    export HYPRLAND_INSTANCE_SIGNATURE="''${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)}"
  '';

  # do: create a headless output, make it 1440p@90, then disable the Dell so the
  # virtual output is the sole active display.
  startVirtualDisplay = pkgs.writeShellApplication {
    name = "sunshine-vdisplay-start";
    runtimeInputs = [
      pkgs.hyprland # hyprctl
      pkgs.jq # parse `hyprctl -j` JSON
      pkgs.coreutils # ls/head/echo (service PATH is null)
    ];
    # SC2012: ls is fine here — the Hyprland instance dirs are hex signatures.
    excludeShellChecks = [ "SC2012" ];
    text = hyprEnv + ''
      # Snapshot existing headless outputs, create a new one, then diff to learn
      # its name (Hyprland auto-names them HEADLESS-2, HEADLESS-3, ...).
      before=$(hyprctl -j monitors all | jq -r '[.[] | select(.name | startswith("HEADLESS-")) | .name]')
      hyprctl output create headless
      name=$(hyprctl -j monitors all \
        | jq -r --argjson before "$before" \
          '[.[] | select(.name | startswith("HEADLESS-")) | .name] | map(select(. as $n | ($before | index($n)) | not)) | .[0]')

      if [ -z "$name" ] || [ "$name" = "null" ]; then
        echo "sunshine-vdisplay-start: failed to detect new headless output" >&2
        exit 1
      fi

      # Remember the name so the stop hook can remove exactly this output.
      echo "$name" > "$XDG_RUNTIME_DIR/sunshine-headless"

      # Match the resolution/refresh the Moonlight client requested. Sunshine
      # exports these to prep-cmd, so the Steam Deck handheld streams at 1440p90
      # and, when docked with Moonlight set to 4K60, a 4K virtual display is
      # created automatically — no config change needed. Falls back to 1440p90
      # if the variables are unset (e.g. when run by hand).
      width="''${SUNSHINE_CLIENT_WIDTH:-2560}"
      height="''${SUNSHINE_CLIENT_HEIGHT:-1440}"
      fps="''${SUNSHINE_CLIENT_FPS:-90}"
      # `auto` placement avoids the overlap warning from stacking at 0x0;
      # position is irrelevant to the stream (Sunshine captures by output name).
      hyprctl keyword monitor "$name,''${width}x''${height}@''${fps},auto,1"
      # Turn off the physical Dell ultrawide for the duration of the stream.
      hyprctl keyword monitor "DP-4,disable"
    '';
  };

  # undo: restore the Dell at its native res/scale, remove the headless output.
  stopVirtualDisplay = pkgs.writeShellApplication {
    name = "sunshine-vdisplay-stop";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.coreutils # cat/rm
    ];
    # SC2012: ls is fine here — the Hyprland instance dirs are hex signatures.
    excludeShellChecks = [ "SC2012" ];
    text = hyprEnv + ''
      # Re-enable the Dell U4025QW (must match hosts/framework-desktop/home.nix).
      hyprctl keyword monitor "DP-4,5120x2160@120,0x0,1.25"

      name=$(cat "$XDG_RUNTIME_DIR/sunshine-headless" 2>/dev/null || true)
      if [ -n "$name" ]; then
        hyprctl output remove "$name" || true
      fi
      rm -f "$XDG_RUNTIME_DIR/sunshine-headless"
    '';
  };

  # Shared by both apps: build the virtual display before the stream, tear it
  # down after. Sunshine runs "do" on stream start and "undo" on stream stop.
  displayPrep = [
    {
      do = "${startVirtualDisplay}/bin/sunshine-vdisplay-start";
      undo = "${stopVirtualDisplay}/bin/sunshine-vdisplay-stop";
    }
  ];

  # Launch Steam Big Picture onto the (now sole) virtual display. Use the system
  # profile path because programs.steam's FHS-wrapped `steam` lives there and the
  # user service's PATH is null. The steam:// URL opens Big Picture if Steam is
  # already running, or starts Steam straight into it otherwise.
  steamBigPicture = "/run/current-system/sw/bin/steam steam://open/bigpicture";

  # Gracefully shut Steam down when the stream ends, so Big Picture doesn't stay
  # open on the desktop after you quit. `-shutdown` asks a running Steam to close.
  steamShutdown = "/run/current-system/sw/bin/steam -shutdown";
in
{
  services.sunshine = {
    enable = true;
    package = pkgsSunshine.sunshine; # newer release than main nixpkgs (see above)
    autoStart = true; # start with the graphical session
    openFirewall = true; # open the Moonlight TCP/UDP ports

    # Hyprland is wlroots-based, so Sunshine captures via wlr-screencopy and does
    # not need CAP_SYS_ADMIN. Leaving this off also avoids prep commands running
    # in an elevated context. Flip to true only if capture yields a black screen.
    capSysAdmin = false;

    settings = {
      # Allow reaching the config/pairing web UI from other LAN devices.
      origin_web_ui_allowed = "lan";
      # output_name is intentionally unset: with the Dell disabled, the headless
      # output is the only active display, so Sunshine captures it automatically.
    };

    applications.apps = [
      {
        name = "Steam Big Picture";
        # First entry: create/restore the virtual display (shared logic).
        # Second entry: on stream end, also shut Steam down (empty `do`, so it
        # only acts on `undo`). Sunshine runs undo steps in reverse order, so
        # Steam is closed before the display is torn back down.
        prep-cmd = displayPrep ++ [
          {
            do = "";
            undo = steamShutdown;
          }
        ];
        # `detached` runs for the session and is NOT killed when the stream ends,
        # so the session is driven by the prep-cmd lifecycle, not the launcher.
        detached = [ steamBigPicture ];
        auto-detach = "true";
      }
      {
        name = "Desktop";
        prep-cmd = displayPrep;
        auto-detach = "true";
      }
    ];
  };

  # The sunshine module already enables hardware.uinput. Add the user to the
  # input/uinput groups so the streamed controller/keyboard/mouse can drive the
  # emulated input devices.
  users.users.${user.name}.extraGroups = [
    "input"
    "uinput"
  ];
}
