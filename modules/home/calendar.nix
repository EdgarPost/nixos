# ============================================================================
# CALENDAR & CONTACTS - vdirsyncer + khal + khard
# ============================================================================
#
# ARCHITECTURE:
#   vdirsyncer (sync) → local vdir files → khal (calendars)
#                                        → khard (contacts)
#
# PROVIDERS SUPPORTED:
#   - Fastmail (CalDAV/CardDAV) - app password in 1Password
#   - Google Calendar (OAuth2) - TODO
#   - Microsoft 365 (OAuth2) - TODO
#
# SETUP:
#   1. Create an App Password in Fastmail:
#      Settings → Privacy & Security → Integrations → App Passwords
#      Create one for "CalDAV/CardDAV" access
#
#   2. Store in 1Password (Personal vault) as "FastMail":
#      - username: your-email@fastmail.com
#      - app-password: (app password from step 1)
#
#   3. Run initial sync: vdirsyncer discover && vdirsyncer sync
#
# USAGE:
#   khal interactive          # TUI calendar view
#   khal calendar             # Show upcoming events
#   khal new 2024-01-15 10:00 12:00 Meeting with Bob
#   khard list                # List contacts
#   khard show "Bob"          # Show contact details
#
# NOTIFICATIONS:
#   Systemd timer runs every 5 minutes, notifies of upcoming events
#
# ============================================================================

{ config, pkgs, lib, ... }:

let
  # Local storage paths
  calendarDir = "${config.xdg.dataHome}/calendars";
  contactsDir = "${config.xdg.dataHome}/contacts";

  # Helper scripts for 1Password credential fetching
  # Uses system `op` wrapper (/run/wrappers/bin/op) which has desktop app integration
  getFastmailUser = pkgs.writeShellScript "get-fastmail-user" ''
    /run/wrappers/bin/op read "op://Personal/FastMail/username"
  '';
  getFastmailPass = pkgs.writeShellScript "get-fastmail-pass" ''
    /run/wrappers/bin/op read "op://Personal/FastMail/app-password"
  '';

  # Notification script for upcoming events
  notifyScript = pkgs.writeShellScript "calendar-notify" ''
    # Check for events starting in the next 15 minutes
    upcoming=$(${pkgs.khal}/bin/khal list now 15m --format "{title} at {start-time}" 2>/dev/null)

    if [ -n "$upcoming" ]; then
      echo "$upcoming" | while IFS= read -r event; do
        ${pkgs.libnotify}/bin/notify-send -u normal "📅 Coming up" "$event"
      done
    fi
  '';

  # Sync script that handles 1Password auth
  syncScript = pkgs.writeShellScript "calendar-sync" ''
    # Sync calendars and contacts via vdirsyncer
    ${pkgs.vdirsyncer}/bin/vdirsyncer sync
  '';
in
{
  home.packages = with pkgs; [
    vdirsyncer    # CalDAV/CardDAV sync
    khal          # TUI calendar
    khard         # TUI contacts
    libnotify     # notify-send for notifications
  ];

  # ===========================================================================
  # VDIRSYNCER - CalDAV/CardDAV Sync
  # ===========================================================================
  xdg.configFile."vdirsyncer/config".text = ''
    [general]
    status_path = "${config.xdg.dataHome}/vdirsyncer/status/"

    # =========================================================================
    # FASTMAIL CALENDARS
    # =========================================================================
    [pair fastmail_calendars]
    a = "fastmail_calendars_remote"
    b = "fastmail_calendars_local"
    collections = ["from a", "from b"]
    metadata = ["color"]
    conflict_resolution = "a wins"

    [storage fastmail_calendars_remote]
    type = "caldav"
    url = "https://caldav.fastmail.com/"
    username.fetch = ["command", "${getFastmailUser}"]
    password.fetch = ["command", "${getFastmailPass}"]

    [storage fastmail_calendars_local]
    type = "filesystem"
    path = "${calendarDir}/fastmail"
    fileext = ".ics"

    # =========================================================================
    # FASTMAIL CONTACTS
    # =========================================================================
    [pair fastmail_contacts]
    a = "fastmail_contacts_remote"
    b = "fastmail_contacts_local"
    collections = ["from a", "from b"]
    conflict_resolution = "a wins"

    [storage fastmail_contacts_remote]
    type = "carddav"
    url = "https://carddav.fastmail.com/"
    username.fetch = ["command", "${getFastmailUser}"]
    password.fetch = ["command", "${getFastmailPass}"]

    [storage fastmail_contacts_local]
    type = "filesystem"
    path = "${contactsDir}/fastmail"
    fileext = ".vcf"
  '';

  # ===========================================================================
  # KHAL - Calendar TUI
  # ===========================================================================
  xdg.configFile."khal/config".text = ''
    [calendars]

    [[fastmail]]
    path = ${calendarDir}/fastmail/*
    type = discover
    color = auto

    [default]
    # Don't set default_calendar - use first available
    highlight_event_days = True

    [locale]
    timeformat = %H:%M
    dateformat = %d/%m/%Y
    longdateformat = %d/%m/%Y
    datetimeformat = %d/%m/%Y %H:%M
    longdatetimeformat = %d/%m/%Y %H:%M
    weeknumbers = right
    firstweekday = 1

    [view]
    frame = color
    bold_for_light_color = False
  '';

  # ===========================================================================
  # KHARD - Contacts TUI
  # ===========================================================================
  xdg.configFile."khard/khard.conf".text = ''
    [addressbooks]

    [[fastmail]]
    path = ${contactsDir}/fastmail/

    [general]
    default_action = list
    editor = nvim
    merge_editor = nvim

    [contact table]
    display = formatted_name
    group_by_addressbook = yes
    reverse = no
    show_nicknames = yes
    show_uids = no
    sort = formatted_name
    localize_dates = yes

    [vcard]
    private_objects =
    search_in_source_files = yes
    skip_unparsable = no
  '';

  # ===========================================================================
  # SYSTEMD TIMERS
  # ===========================================================================

  # Sync timer - every 15 minutes
  systemd.user.services.vdirsyncer-sync = {
    Unit = {
      Description = "Sync calendars and contacts";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}";
    };
  };

  systemd.user.timers.vdirsyncer-sync = {
    Unit = {
      Description = "Sync calendars and contacts periodically";
    };
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Notification timer - every 5 minutes
  systemd.user.services.calendar-notify = {
    Unit = {
      Description = "Calendar event notifications";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${notifyScript}";
    };
  };

  systemd.user.timers.calendar-notify = {
    Unit = {
      Description = "Check for upcoming calendar events";
    };
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # ===========================================================================
  # SHELL INTEGRATION
  # ===========================================================================
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
