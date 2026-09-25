# devenv module: installs the GitHub Copilot CLI inside a devenv shell,
# optionally wrapped with the Headroom token compressor.
#
# Usage (devenv.nix):
#   { pkgs, inputs, ... }: {
#     imports = [ inputs.copilot-cli-flake.devenvModules.default ];
#     copilotCli.enable = true;
#     copilotCli.headroom.enable = true; # optional
#   }
{ config, lib, pkgs, ... }:
let
  cfg = config.copilotCli;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.copilotCli = wrapperLib.mkOptions { inherit lib pkgs; };

  config = lib.mkIf cfg.enable {
    packages = wrapperLib.mkPackages { inherit pkgs cfg; };
  };
}
