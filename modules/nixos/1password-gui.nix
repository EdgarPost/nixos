{ user, ... }:

{
  # 1Password GUI application
  programs._1password-gui = {
    enable = true;
    # polkitPolicyOwners: Users allowed to unlock 1Password via fingerprint/password
    # Required for browser integration and system auth dialogs
    polkitPolicyOwners = [ user.name ];
  };
}
