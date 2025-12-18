{ config, pkgs, user, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
      # Auto-login (optional, comment out if you want login prompt)
      # initial_session = {
      #   command = "Hyprland";
      #   user = user.name;
      # };
    };
  };
}
