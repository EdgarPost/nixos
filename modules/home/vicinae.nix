{ inputs, ... }:

{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    settings = {
      theme = {
        dark.name = "catppuccin-mocha";
        light.name = "catppuccin-mocha";
      };
      font.rendering = "native";
      favorites = [ ];
      launcher_window.compact_mode.enabled = true;
    };
  };

  wayland.windowManager.hyprland = {
    settings.bind = [
      "$hyper, D, exec, vicinae toggle"
      "$hyper, V, exec, vicinae vicinae://launch/clipboard/history"
    ];

    extraConfig = ''
      layerrule {
          name = vicinae-blur
          blur = on
          ignore_alpha = 0
          match:namespace = vicinae
      }

      layerrule {
          name = vicinae-no-animation
          no_anim = on
          match:namespace = vicinae
      }
    '';
  };
}
