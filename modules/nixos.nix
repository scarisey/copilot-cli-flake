{ config, lib, pkgs, ... }:
let
  cfg = config.programs.copilotHeadroom;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.programs.copilotHeadroom = wrapperLib.mkOptions { inherit lib pkgs; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
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
