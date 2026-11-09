{
  stdenv,
  fetchurl,
  patchelf,
  makeWrapper,
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

  isLinux = stdenv.hostPlatform.isLinux;
in

stdenv.mkDerivation rec {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@github/${platform.pkgName}/-/${platform.pkgName}-${version}.tgz";
    sha256 = platform.sha256;
  };

  # NOTE: deliberately do *not* use autoPatchelfHook here.
  #
  # The Copilot CLI is a Node single-executable application (SEA) with a
  # statically linked Node/OpenSSL whose dynamic symbols are exported by the
  # main executable. Copilot's vendored `copilot-openssl` loader validates
  # those symbols when it needs a native OpenSSL runtime (e.g. for proxy TLS
  # certificate parsing).
  #
  # autoPatchelfHook adds an RPATH/RUNPATH to the executable. Doing so forces
  # patchelf to grow `.dynstr`, which relocates it to an address outside the
  # mapped PT_LOAD segments. The loader then aborts with:
  #
  #   cannot verify the selected libcrypto symbol table (... lie outside the
  #   readable image); refusing an unverified OpenSSL runtime
  #
  # Patching only the ELF interpreter preserves the original section layout,
  # so we do that manually and supply the runtime libraries (libstdc++ etc.)
  # through LD_LIBRARY_PATH in the wrapper instead of an RPATH.
  dontAutoPatchelf = true;

  nativeBuildInputs = lib.optionals isLinux [ patchelf makeWrapper ];
  buildInputs = lib.optionals isLinux [ stdenv.cc.cc.lib ];

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    ${lib.optionalString isLinux ''
      mkdir -p $out/libexec
      install -m755 copilot $out/libexec/copilot

      # Only set the interpreter: adding an RPATH breaks the SEA layout (see
      # the comment above dontAutoPatchelf).
      patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} $out/libexec/copilot

      makeWrapper $out/libexec/copilot $out/bin/copilot \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}
    ''}

    ${lib.optionalString (!isLinux) ''
      install -m755 copilot $out/bin/copilot
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Github Copilot CLI";
    homepage = "https://github.com";
    mainProgram = "copilot";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
