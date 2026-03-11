{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(hyper, capslock)";
        };
        "hyper:C-M-A-S" = { };
      };
    };
  };
}
