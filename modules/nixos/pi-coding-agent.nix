# ============================================================================
# PI CODING AGENT - Minimal NixOS module (pi from nixpkgs)
# ============================================================================
#
# Used to come from the pi-mono flake input (inputs.pi-mono.nixosModules.
# default), which pulled the whole pi-mono build system (bun2nix, jail-nix,
# nodejs pinning) and tracked upstream pi releases with a custom package.
#
# Now pi is packaged in nixpkgs (`pkgs.pi-coding-agent`, chases the latest
# upstream release tag via nix-update-script — a release or two behind
# pi-mono is fine for us). The nixpkgs package ships no NixOS module, so
# this is a minimal port of pi-mono's `programs.pi.coding-agent` surface
# covering exactly the options this config uses: enable / package /
# extensions / skills. Anything fancier (jail, models, environment,
# settings merge) can be re-ported here if ever needed.
#
# ============================================================================

{ config, pkgs, lib, ... }:

let
  cfg = config.programs.pi.coding-agent;

  pathFlags =
    flag: paths:
    lib.concatMap (path: [
      flag
      "${path}"
    ]) paths;

  resourceArgs =
    pathFlags "--skill" cfg.skills
    ++ pathFlags "--extension" cfg.extensions;

  argsStr = lib.concatMapStringsSep " " lib.escapeShellArg resourceArgs;
in
{
  options.programs.pi.coding-agent = {
    enable = lib.mkEnableOption "pi agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pi-coding-agent;
      description = "The pi coding-agent package to install.";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      default = [ ];
      description = ''
        Extension paths to pass to pi via repeated `--extension` flags for every invocation.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Skill paths to pass to pi via repeated `--skill` flags for every invocation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (if resourceArgs == [ ] then
        cfg.package
      else
        pkgs.writeShellScriptBin "pi" ''
          exec ${lib.escapeShellArg (lib.getExe cfg.package)} ${argsStr} "$@"
        '')
    ];
  };
}