# ============================================================================
# THUNDERBIRD - Email, Calendar & Contacts
# ============================================================================
#
# All-in-one client for:
#   - Email (IMAP/SMTP via Fastmail)
#   - Calendar (CalDAV via Fastmail, with native alarm support)
#   - Contacts (CardDAV via Fastmail)
#
# SETUP (per machine, one-time):
#   1. Open Thunderbird → enter Fastmail app password when prompted
#   2. Calendar: Add CalDAV → https://caldav.fastmail.com/
#   3. Contacts: Add CardDAV → https://carddav.fastmail.com/
#   Credentials: use Fastmail app password from 1Password
#
# ============================================================================

{ user, ... }:

{
  accounts.email.accounts.fastmail = {
    address = user.email;
    realName = user.fullName;
    userName = user.email;
    primary = true;

    imap = {
      host = "imap.fastmail.com";
      port = 993;
      tls.enable = true;
    };

    smtp = {
      host = "smtp.fastmail.com";
      port = 465;
      tls.enable = true;
    };

    thunderbird = {
      enable = true;
      profiles = [ "default" ];
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
