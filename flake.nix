{
  description = "A development shell for the GitHub Copilot CLI (Node Module)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {inherit system;pkgs=(import nixpkgs {inherit system;});});
      wrapperLib = import ./modules/lib.nix { lib = nixpkgs.lib; };
    in {
      packages =  forAllSystems ({system,pkgs}: {
        default = pkgs.callPackage ./package.nix {};
        headroom = pkgs.callPackage ./headroom.nix {};
        copilot-hr = wrapperLib.mkWrapper {
          inherit pkgs;
          copilotPackage = pkgs.callPackage ./package.nix {};
          headroomPackage = pkgs.callPackage ./headroom.nix {};
          wrapperName = "copilot-hr";
          port = 8787;
          subscription = false;
          extraWrapArgs = [ ];
        };
      });
      devShells = forAllSystems ({system,pkgs}:
        {
          updateShell = pkgs.mkShell {
            packages = [
              pkgs.nodejs_latest
              pkgs.jq
            ];
          };
          default = pkgs.mkShell {
            packages = [
              pkgs.nodejs_latest
              self.packages.${system}.default
              self.packages.${system}.headroom
              self.packages.${system}.copilot-hr
            ];

            shellHook = ''
                echo ${self.packages.${system}.default}
                echo "✅ 'copilot' command is now available."
                echo "✅ 'copilot-hr' (copilot wrapped with Headroom) is now available."
            '';
            NIX_SHELL_PRESERVE_ENVIRONMENT = [ "HOME" ];
          };
        }
      );

      nixosModules.copilotCli = ./modules/nixos.nix;
      nixosModules.default = self.nixosModules.copilotCli;

      homeManagerModules.copilotCli = ./modules/home-manager.nix;
      homeManagerModules.default = self.homeManagerModules.copilotCli;

      devenvModules.copilotCli = ./modules/devenv.nix;
      devenvModules.default = self.devenvModules.copilotCli;
    };
}
