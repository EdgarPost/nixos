# ============================================================================
# NOCTALIA - Wayland Desktop Shell (bar, notifications, launcher, dock, etc.)
# ============================================================================
#
# Noctalia is the unified shell layer on top of Hyprland. It replaces the
# previous waybar + swaync stack: status bar, notifications, launcher,
# clipboard, control center, and wallpaper picker all come from Noctalia.
#
# Settings live in `noctalia-settings.toml` next to this file. The TOML is
# noctalia's native format, so home-manager's `programs.noctalia` module
# validates it at build time (checkConfig) and ships it as
# ~/.config/noctalia/config.toml.
#
# The option + service wiring comes from home-manager's upstream module
# (modules/programs/noctalia). This file only adds what upstream does not
# provide: the GUI -> repo settings sync below and the screen recorder
# backend.
#
# WORKFLOW for changing settings:
#   1. Tweak in Noctalia's GUI
#   2. A systemd user PATH unit syncs the change back into this file
#      automatically (noctalia-settings-sync.service) — see below.
#   3. git add modules/home/noctalia-settings.toml && git commit
#   4. sudo nixos-rebuild switch --flake .#<host>
#
# Manual fallback (if the sync ever stops):
#   noctalia config export > modules/home/noctalia-settings.toml
#
# Docs: https://docs.noctalia.dev/v5/
# Alpha: expect breaking config changes between releases.
#
# ============================================================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.noctalia;

  # Real on-disk repo path of the tracked settings file. Used by the
  # GUI->repo sync below (a ./path literal would point into the read-only
  # nix store once the flake is evaluated).
  settingsTarget = "${config.home.homeDirectory}/Code/github.com/EdgarPost/nixos/modules/home/noctalia-settings.toml";
in
{
  programs.noctalia = {
    enable = true;

    # Systemd service auto-starts with the graphical session
    systemd.enable = true;

    # Path to a tracked TOML file. The module validates it at build time
    # and copies it to ~/.config/noctalia/config.toml on activation.
    settings = ./noctalia-settings.toml;
  };

  # The official screen_recorder plugin records with gpu-screen-recorder,
  # which it expects on PATH. The plugin itself is already enabled in
  # noctalia-settings.toml ([plugins] enabled = [ "noctalia/screen_recorder" ]).
  # https://noctalia.dev/plugins/official/screen_recorder
  home.packages = [
    pkgs.gpu-screen-recorder # Hardware-accelerated screen recording backend
  ];

  # ======================================================================
  # GUI -> REPO SETTINGS SYNC
  # ======================================================================
  # The GUI edits settings (bar, wallpaper, plugins, ...) and the app
  # persists them to ~/.local/state/noctalia/settings.toml (that file
  # wins over the generated config.toml). To get those changes back into
  # this tracked file we used to run, by hand:
  #
  #   noctalia config export > modules/home/noctalia-settings.toml
  #
  # A systemd user PATH unit watches the state file and re-runs that
  # export automatically on every change: noctalia-settings-sync.path
  # triggers noctalia-settings-sync.service (debounced by 2s so slider
  # drags collapse into one export). The service also runs once at login
  # to catch changes made while the watch was not running. After a GUI
  # tweak the repo file is updated, so `git status` shows it and you just
  # commit it like any other change.
  #
  # Note: export writes the file fresh (canonical order, no comments), so
  # comments in noctalia-settings.toml are transient.
  systemd.user = {
    services.noctalia-settings-sync = {
      Unit = {
        Description = "Sync noctalia GUI settings into the config repo";
      };
      Service = {
        Type = "oneshot";
        # Note: target the REAL repo path on disk. A `./noctalia-settings.toml`
        # path literal would resolve into the read-only nix store when the
        # flake is evaluated, so the export would fail to write.
        ExecStart = toString (
          pkgs.writeShellScript "noctalia-settings-sync" ''
            sleep 2
            ${lib.getExe cfg.package} config export > "${settingsTarget}"
          ''
        );
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
    paths.noctalia-settings-sync = {
      Unit.Description = "Watch noctalia settings.toml for GUI changes";
      Path.PathChanged = "%h/.local/state/noctalia/settings.toml";
      Install.WantedBy = [ "default.target" ];
    };
  };
}
