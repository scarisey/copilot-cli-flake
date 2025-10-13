{
  buildNpmPackage,
  fetchurl,
  pkgs
}:
let
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
  pname = "github-copilot-cli";
  version = versions.version;
in

buildNpmPackage rec {
  inherit pname version;

  dontBuild = true;

  src = fetchurl {
    url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
    sha256 = versions.sha256;
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = versions.npmDepsHash;

  nativeBuildInputs = [ pkgs.nodejs ];

  meta = {
    description = "Github Copilot CLI";
    homepage = "https://github.com";
  };
}
