{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  lib,
}:
let
  versions = builtins.fromJSON (builtins.readFile ./versions.json);
  pname = "github-copilot-cli";
  version = versions.version;

  platformMap = {
    "x86_64-linux"  = { pkgName = "copilot-linux-x64";   sha256 = versions.sha256Linux_x64; };
    "aarch64-linux" = { pkgName = "copilot-linux-arm64";  sha256 = versions.sha256Linux_arm64; };
    "x86_64-darwin" = { pkgName = "copilot-darwin-x64";  sha256 = versions.sha256Darwin_x64; };
    "aarch64-darwin"= { pkgName = "copilot-darwin-arm64"; sha256 = versions.sha256Darwin_arm64; };
  };

  platform = platformMap.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@github/${platform.pkgName}/-/${platform.pkgName}-${version}.tgz";
    sha256 = platform.sha256;
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp copilot $out/bin/copilot
    chmod +x $out/bin/copilot
    runHook postInstall
  '';

  meta = {
    description = "Github Copilot CLI";
    homepage = "https://github.com";
    mainProgram = "copilot";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
