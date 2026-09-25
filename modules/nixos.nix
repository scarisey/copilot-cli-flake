{ config, lib, pkgs, ... }:
let
  cfg = config.programs.copilotCli;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.programs.copilotCli = wrapperLib.mkOptions { inherit lib pkgs; };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = wrapperLib.mkPackages { inherit pkgs cfg; };
  };
}
