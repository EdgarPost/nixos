{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" "-mouse" ];
      settings = {
        main = {
          capslock = "layer(hyper)"; # hold = hyper, tap does nothing (Caps Lock disabled)
        };
        meta = {
          left = "home";
          right = "end";
        };
        "hyper:C-M-A-S" = { };
      };
    };
  };
}
