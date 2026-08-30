# ============================================================================
# NOCTALIA - Wayland Desktop Shell (bar, notifications, launcher, dock, etc.)
# ============================================================================
#
# Noctalia is the unified shell layer on top of Hyprland. It replaces the
# previous waybar + swaync stack: status bar, notifications, launcher,
# clipboard, control center, and wallpaper picker all come from Noctalia.
#
# Settings live in `noctalia-settings.toml` next to this file. The TOML is
# noctalia's native format, so this module points at it and the
# `noctalia config validate` step (run at build time) catches any issues.
#
# The `programs.noctalia` module used to come from the noctalia flake input;
# now the package is stock nixpkgs (pkgs.noctalia, which tracks the latest
# v5.x release tag), so this module re-implements the home-manager wiring:
# systemd user service + config file generation + build-time validation.
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
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  # Real on-disk repo path of the tracked settings file. Used by the
  # GUI->repo sync below (a ./path literal would point into the read-only
  # nix store once the flake is evaluated).
  settingsTarget = "${config.home.homeDirectory}/Code/github.com/EdgarPost/nixos/modules/home/noctalia-settings.toml";

  generateConfig =
    format: name: value:
    if lib.isString value then
      pkgs.writeText name value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      format.generate name value;

  generateToml = generateConfig tomlFormat;
  generateJson = generateConfig jsonFormat;
in
{
  # Disable the home-manager module if it ever gets one upstream
  disabledModules = [ "programs/noctalia.nix" ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "noctalia" "validateConfig" ]
      [ "programs" "noctalia" "checkConfig" ]
    )
  ];

  options.programs.noctalia = {
    enable = lib.mkEnableOption "noctalia, a lightweight Wayland shell and bar";

    systemd.enable = lib.mkEnableOption "a systemd user service for noctalia";

    package = lib.mkPackageOption pkgs "noctalia" { nullable = true; };

    checkConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Validate the configuration file at build time.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          tomlFormat.type
          str
          path
        ];
      default = { };
      description = ''
        Default settings for noctalia, Can be written as:
          - A Nix attrset (converted to TOML via nixpkgs' tomlFormat)
          - A raw TOML string
          - A path to a `.toml` file

        See <https://docs.noctalia.dev/noctalia/configuration/> for more information and examples.

        Note: these settings can still be overwritten at runtime via the settings menu.
      '';
      example = lib.literalExpression ''
        shell = {
          font = "JetBrainsMono Nerd Font";
          settings_show_advanced = true;
        };

        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
      '';
    };

    customPalettes = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          jsonFormat.type
          str
          path
        ]);
      default = { };
      description = ''
        Custom color palette options.

        See <https://docs.noctalia.dev/noctalia/theming/palette/#custom-palette-files>.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # ENABLE: wire noctalia into this home (package comes from nixpkgs)
      programs.noctalia = {
        enable = true;

        # Systemd service auto-starts on hyprland-session.target
        systemd.enable = true;

        # Path to a tracked TOML file. The module validates it at build
        # time and copies it to ~/.config/noctalia/config.toml on activation.
        settings = ./noctalia-settings.toml;
      };

      # The official screen_recorder plugin records with gpu-screen-recorder,
      # which it expects on PATH. The plugin itself is already enabled in
      # noctalia-settings.toml ([plugins] enabled = [ "noctalia/screen_recorder" ]).
      # https://noctalia.dev/plugins/official/screen_recorder
      home.packages = with pkgs; [
        gpu-screen-recorder # Hardware-accelerated screen recording backend
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
    (lib.mkIf cfg.enable {
      systemd.user.services.noctalia = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Noctalia - A lightweight Wayland shell and bar";
        Documentation = "https://docs.noctalia.dev/noctalia/";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        X-Restart-Triggers =
          lib.optional (cfg.settings != { }) "${config.xdg.configFile."noctalia/config.toml".source}"
          ++ lib.mapAttrsToList (
            name: _: "${config.xdg.configFile."noctalia/palettes/${name}.json".source}"
          ) cfg.customPalettes;
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg = {
      configFile = lib.mkMerge [
        (lib.mkIf (cfg.settings != { }) {
          "noctalia/config.toml".source =
            let
              rawConfig = generateToml "config.toml" cfg.settings;
            in
            if cfg.checkConfig && cfg.package != null then
              pkgs.runCommand "noctalia-config.toml" { } ''
                ${lib.getExe cfg.package} config validate ${rawConfig}
                cp ${rawConfig} $out
              ''
            else
              rawConfig;
        })
        (lib.mapAttrs' (
          name: palette:
          lib.nameValuePair "noctalia/palettes/${name}.json" {
            source = generateJson "${name}-palette.json" palette;
          }
        ) cfg.customPalettes)
      ];
    };

      assertions = [
        {
          assertion = !cfg.systemd.enable || cfg.package != null;
          message = "programs.noctalia.package cannot be null when programs.noctalia.systemd.enable is true";
        }
      ];
    })
  ];

  _class = "homeManager";
}