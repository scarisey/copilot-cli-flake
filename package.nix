{
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper
}:
let
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
  pname = "github-copilot-cli";
  version = versions.version;
in

stdenv.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
    sha256 = versions.sha256;
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@github/copilot
    cp -r . $out/lib/node_modules/@github/copilot
    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/copilot \
      --add-flags "$out/lib/node_modules/@github/copilot/index.js"
    runHook postInstall
  '';

  meta = {
    description = "Github Copilot CLI";
    homepage = "https://github.com";
  };
}
