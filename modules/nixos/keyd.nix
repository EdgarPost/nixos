{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" "-mouse" ];
      settings = {
        main = {
          capslock = "overload(hyper, capslock)";
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
