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
#   1. Email: Add Fastmail account (auto-discovers IMAP/SMTP settings)
#   2. Calendar: Add CalDAV → https://caldav.fastmail.com/
#   3. Contacts: Add CardDAV → https://carddav.fastmail.com/
#   Credentials: use Fastmail app password from 1Password
#
# ============================================================================

{
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
