# devenv module: wraps GitHub Copilot CLI with the Headroom token
# compressor inside a devenv shell.
#
# Usage (devenv.nix):
#   { pkgs, inputs, ... }: {
#     imports = [ inputs.copilot-cli-flake.devenvModules.default ];
#     copilotHeadroom.enable = true;
#   }
{ config, lib, pkgs, ... }:
let
  cfg = config.copilotHeadroom;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.copilotHeadroom = wrapperLib.mkOptions { inherit lib pkgs; };

  config = lib.mkIf cfg.enable {
    packages = [
      (wrapperLib.mkWrapper {
        inherit pkgs;
        inherit (cfg)
          copilotPackage
          headroomPackage
          wrapperName
          port
          subscription
          extraWrapArgs
          ;
      })
    ];
  };
}
