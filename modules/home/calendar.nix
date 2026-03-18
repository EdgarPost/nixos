# ============================================================================
# CALENDAR & CONTACTS - vdirsyncer + khal + khard (declarative)
# ============================================================================
#
# ARCHITECTURE:
#   vdirsyncer (systemd timer, every 15 min)
#     └── Fastmail CalDAV + CardDAV (includes Gmail calendars)
#           ↓
#     ~/.local/share/calendars/  +  ~/.local/share/contacts/
#           ↓
#     khal (TUI calendar)  +  khard (TUI contacts)
#           ↓
#     notify-send → swaync (every 5 min)
#
# SETUP:
#   1. Create an App Password in Fastmail:
#      Settings → Privacy & Security → Integrations → App Passwords
#      Create one for "CalDAV/CardDAV" access
#
#   2. Store in 1Password (Private vault) as "FastMail":
#      - username: your-email@fastmail.com
#      - vdirsyncer: (app password from step 1)
#
#   3. Run initial sync: vdirsyncer discover && vdirsyncer sync
#
# ============================================================================

{ config, pkgs, lib, ... }:

let
  cacheDir = "\${XDG_RUNTIME_DIR}/vdirsyncer";

  # Cache credentials at login so 1Password is only prompted once per session.
  # Wrapper scripts read from cache, falling back to op if cache is missing.
  cacheCredentials = pkgs.writeShellScript "cache-vdirsyncer-creds" ''
    mkdir -p "${cacheDir}"
    chmod 700 "${cacheDir}"
    op read "op://Private/FastMail/username" > "${cacheDir}/username"
    op read "op://Private/FastMail/vdirsyncer" > "${cacheDir}/password"
    chmod 600 "${cacheDir}/username" "${cacheDir}/password"
  '';

  getUser = pkgs.writeShellScript "get-fastmail-user" ''
    if [ -f "${cacheDir}/username" ]; then
      cat "${cacheDir}/username"
    else
      op read "op://Private/FastMail/username"
    fi
  '';
  getPass = pkgs.writeShellScript "get-fastmail-pass" ''
    if [ -f "${cacheDir}/password" ]; then
      cat "${cacheDir}/password"
    else
      op read "op://Private/FastMail/vdirsyncer"
    fi
  '';

  notifyScript = pkgs.writeShellScript "calendar-notify" ''
    upcoming=$(${pkgs.khal}/bin/khal list now 15m --format "{title} at {start-time}" 2>/dev/null)

    if [ -n "$upcoming" ]; then
      echo "$upcoming" | while IFS= read -r event; do
        ${pkgs.libnotify}/bin/notify-send -u normal "📅 Coming up" "$event"
      done
    fi
  '';
in
{
  # ===========================================================================
  # ACCOUNTS
  # ===========================================================================

  accounts.calendar.basePath = "calendars";

  accounts.calendar.accounts.fastmail = {
    remote = {
      type = "caldav";
      url = "https://caldav.fastmail.com/";
      passwordCommand = [ "${getPass}" ];
    };
    vdirsyncer = {
      enable = true;
      collections = [ "from a" "from b" ];
      metadata = [ "color" "displayname" ];
      conflictResolution = "remote wins";
      userNameCommand = [ "${getUser}" ];
    };
    khal = {
      enable = true;
      type = "discover";
    };
  };

  accounts.contact.basePath = "contacts";

  accounts.contact.accounts.fastmail = {
    remote = {
      type = "carddav";
      url = "https://carddav.fastmail.com/";
      passwordCommand = [ "${getPass}" ];
    };
    vdirsyncer = {
      enable = true;
      collections = [ "from a" "from b" ];
      conflictResolution = "remote wins";
      userNameCommand = [ "${getUser}" ];
    };
    khard.enable = true;
  };

  # ===========================================================================
  # PROGRAMS
  # ===========================================================================

  programs.vdirsyncer.enable = true;

  programs.khal = {
    enable = true;
    settings = {
      default.default_calendar = "Default";
      view = {
        theme = "dark";
        frame = "color";
        bold_for_light_color = false;
      };
    };
    locale = {
      timeformat = "%H:%M";
      dateformat = "%d/%m/%Y";
      longdateformat = "%d/%m/%Y";
      datetimeformat = "%d/%m/%Y %H:%M";
      longdatetimeformat = "%d/%m/%Y %H:%M";
      weeknumbers = "right";
      firstweekday = 1;
    };
  };

  programs.khard = {
    enable = true;
    settings = {
      general = {
        default_action = "list";
        editor = [ "nvim" ];
        merge_editor = [ "nvim" ];
      };
      "contact table" = {
        display = "formatted_name";
        group_by_addressbook = true;
        reverse = false;
        show_nicknames = true;
        show_uids = false;
        sort = "formatted_name";
        localize_dates = true;
      };
      vcard = {
        search_in_source_files = true;
        skip_unparsable = false;
      };
    };
  };

  # ===========================================================================
  # SERVICES
  # ===========================================================================

  # Cache 1Password credentials at login (stored in XDG_RUNTIME_DIR, cleared on logout)
  systemd.user.services.vdirsyncer-cache-creds = {
    Unit.Description = "Cache Fastmail credentials from 1Password";
    Service = {
      Type = "oneshot";
      ExecStart = "${cacheCredentials}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/15";
  };

  # Notification timer — every 5 minutes
  systemd.user.services.calendar-notify = {
    Unit.Description = "Calendar event notifications";
    Service = {
      Type = "oneshot";
      ExecStart = "${notifyScript}";
    };
  };

  systemd.user.timers.calendar-notify = {
    Unit.Description = "Check for upcoming calendar events";
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # ===========================================================================
  # SHELL INTEGRATION
  # ===========================================================================

  home.packages = [ pkgs.libnotify ];

  programs.fish = {
    shellAliases = {
      cal = "khal interactive";
      contacts = "khard list";
    };

    interactiveShellInit = ''
      function cal-sync --description "Manually sync calendars and contacts"
        echo "Syncing calendars and contacts..."
        vdirsyncer discover
        vdirsyncer sync
        echo "Done!"
      end
    '';
  };
}
