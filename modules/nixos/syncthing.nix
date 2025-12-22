# ============================================================================
# SYNCTHING - Declarative File Synchronization
# ============================================================================
#
# Device IDs are safe to commit - they're public keys.
#
# Usage in host config:
#   services.syncthing.enable = true;          # Code folder only (default)
#   services.syncthing.paraFolders = true;     # Also sync Projects/Areas/Resources
#
# Web UI: http://localhost:8384
#
# ============================================================================

{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  cfg = config.services.syncthing;

  # Code folder - always included when syncthing is enabled
  codeFolders = {
    "ltpeu-5jyss" = {
      label = "Code";
      path = "/home/${user.name}/Code";
      devices = [ "pbstation" ];
    };
  };

  # PARA folders - optional, enabled with paraFolders = true
  paraFolders = {
    "kvnmw-4dzbg" = {
      label = "Projects";
      path = "/home/${user.name}/Projects";
      devices = [ "pbstation" ];
    };
    "fmyuz-f43q9" = {
      label = "Areas";
      path = "/home/${user.name}/Areas";
      devices = [ "pbstation" ];
    };
    "pcdfl-3k5at" = {
      label = "Resources";
      path = "/home/${user.name}/Resources";
      devices = [ "pbstation" ];
      ignorePatterns = [
        "Photos (iPhone)"
        "Photos (Miscellaneous)"
      ];
    };
  };
in
{
  options.services.syncthing.paraFolders = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Also sync PARA folders (Projects, Areas, Resources)";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      user = user.name;
      dataDir = "/home/${user.name}";
      configDir = "/home/${user.name}/.config/syncthing";

      overrideDevices = true;
      overrideFolders = true;

      settings = {
        devices = {
          "pbstation" = {
            id = "BT6TVTI-2QCJ6KW-MJ4WVDZ-ERVANSV-3HZSL4Q-E7SQJBW-IZYD5QA-2CPX5QS";
          };
        };

        # Common ignore patterns for all folders
        defaults.folder.ignorePatterns = [
          "@eaDir"
          "#recycle"
          ".DS_Store"
          "Thumbs.db"
          ".Spotlight-V100"
          ".Trashes"
        ];

        folders = codeFolders // (lib.optionalAttrs cfg.paraFolders paraFolders);

        options.urAccepted = -1;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 21027 ];
    };
  };
}
