{
  description = "A development shell for the GitHub Copilot CLI (Node Module)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {inherit system;pkgs=(import nixpkgs {inherit system;});});
    in {
      packages =  forAllSystems ({system,pkgs}: {
        default = pkgs.callPackage ./package.nix {};
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
            ];

            shellHook = ''
                echo ${self.packages.${system}.default}
                echo "✅ 'copilot' command is now available."
            '';
            NIX_SHELL_PRESERVE_ENVIRONMENT = [ "HOME" ];
          };
        }
      );
    };
}
