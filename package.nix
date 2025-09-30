{
  buildNpmPackage,
  fetchurl,
  pkgs
}:
let
  pname = "github-copilot-cli";
  version = "0.0.330";
in

buildNpmPackage rec {
  inherit pname version;

  dontBuild = true;

  src = fetchurl {
    url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
    sha256 = "sha256-FBizSrJjwkPpPIL5Zus7gci96Wfia6ElxtL3OJWy6jc=";
  };

  postPatch = ''
    cp ${./package-lock.json} ./package-lock.json
  '';

  npmDepsHash = "sha256-roewkjEsNcSYJKx0enDlbp/K83pPSkCrJDylQ1GSYtw=";

  nativeBuildInputs = [ pkgs.nodejs ];
  buildInputs = [ pkgs.cowsay ];

  meta = {
    description = "Github Copilot CLI";
    homepage = "https://github.com";
  };
}
