# ============================================================================
# SYNCTHING - Declarative File Synchronization
# ============================================================================
#
# Device IDs are safe to commit - they're public keys.
# Both devices must mutually approve connections.
#
# Add new device:
#   1. Get Device ID from other device's web UI (Actions > Show ID)
#   2. Add to settings.devices below
#   3. Add device name to each folder's `devices` list
#   4. Rebuild
#
# Web UI: http://localhost:8384
#
# ============================================================================

{
  config,
  pkgs,
  user,
  ...
}:

{
  services.syncthing = {
    enable = true;
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
      # @eaDir = Synology metadata, #recycle = Synology trash
      defaults.folder.ignorePatterns = [
        "@eaDir"
        "#recycle"
        ".DS_Store"
        "Thumbs.db"
        ".Spotlight-V100"
        ".Trashes"
      ];

      folders = {
        "ltpeu-5jyss" = {
          label = "Code";
          path = "/home/${user.name}/Code";
          devices = [ "pbstation" ];
        };
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
}
