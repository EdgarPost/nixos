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
    "jh6n4-jmv36" = {
      label = "Edgar PARA";
      path = "/home/${user.name}/PARA";
      devices = [
        "pbstation"
        "assistant"
      ];
      ignorePatterns = [
        "Photos (iPhone)"
        "Photos (Miscellaneous)"
        "/Archive/*"
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
          "assistant" = {
            id = "E2IUI2O-LZTEVCE-CDXMJT7-7IXGHND-63OQFMK-75MQ6Y4-5DZN5CH-FQ2ZLQU";
          };
        };

        # Common ignore patterns for all folders
        defaults.folder.ignorePatterns = [
          ".git"
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
      allowedUDPPorts = [
        22000
        21027
      ];
    };
  };
}
