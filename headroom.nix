{
  lib,
  stdenv,
  fetchurl,
  python3,
  ast-grep,
}:
let
  versions = builtins.fromJSON (builtins.readFile ./headroom-versions.json);
  pname = "headroom-ai";
  version = versions.version;

  platformMap = {
    "x86_64-linux" = {
      url = versions.urlLinux_x64;
      sha256 = versions.sha256Linux_x64;
    };
    "aarch64-linux" = {
      url = versions.urlLinux_arm64;
      sha256 = versions.sha256Linux_arm64;
    };
    "x86_64-darwin" = {
      url = versions.urlDarwin_x64;
      sha256 = versions.sha256Darwin_x64;
    };
    "aarch64-darwin" = {
      url = versions.urlDarwin_arm64;
      sha256 = versions.sha256Darwin_arm64;
    };
  };

  platform = platformMap.${stdenv.hostPlatform.system};
in

python3.pkgs.buildPythonApplication rec {
  inherit pname version;
  format = "wheel";

  src = fetchurl {
    inherit (platform) url sha256;
  };

  # Upstream's wheel metadata declares `ast-grep-cli` as a required
  # dependency; it only bundles the prebuilt `ast-grep` binary and has no
  # importable Python module, so it's provided via PATH below instead of as
  # a Python package (see `makeWrapperArgs`), which would otherwise make
  # nixpkgs' runtime dependency checker fail.
  dontCheckRuntimeDeps = true;

  propagatedBuildInputs = with python3.pkgs; [
    tiktoken
    pydantic
    litellm
    click
    rich
    opentelemetry-api
    pyyaml
    tomli
    tomlkit
    # `proxy` extra: required to run `headroom proxy` / `headroom wrap <tool>`,
    # which starts the local compression proxy as a subprocess.
    fastapi
    uvicorn
    orjson
    httpx
    h2 # httpx[http2], required by the proxy's outbound HTTP/2 client
    openai
    mcp
    magika
    zstandard
    websockets
    onnxruntime
    transformers
    watchdog
    sqlite-vec
  ];

  # `headroom` shells out to the `ast-grep` binary (declared upstream as a
  # required, non-extra dependency via the `ast-grep-cli` PyPI wheel, which
  # merely bundles the very same prebuilt binary that nixpkgs' `ast-grep`
  # package builds from source). Put the real nixpkgs package on PATH
  # instead of vendoring another copy of the same binary.
  #
  # `headroom wrap <tool>` also starts its local proxy as a *subprocess*
  # via `[sys.executable, "-m", "headroom.cli", "proxy", ...]` rather than
  # calling back into the already-running process. nixpkgs' Python wrapper
  # makes `headroom`'s own site-packages importable by calling
  # `site.addsitedir()` at the top of the wrapped script, not by exporting
  # `PYTHONPATH` — so that bare `sys.executable` subprocess doesn't see them
  # and fails with `ModuleNotFoundError: No module named 'headroom'`.
  # Exporting PYTHONPATH here (in addition to the normal site.addsitedir
  # mechanism) makes it available to every subprocess as well.
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [ ast-grep ]}"
    "--prefix"
    "PYTHONPATH"
    ":"
    "$out/${python3.sitePackages}:${python3.pkgs.makePythonPath propagatedBuildInputs}"
  ];

  # The base package covers the CLI shell and core JSON/code/log
  # compression; the `proxy` extra above additionally lets `headroom proxy`
  # / `headroom wrap <tool>` actually run. Other optional subcommands
  # (ML-based prose compression via Kompress-v2-base, some agent wrappers,
  # …) still import their extra dependencies lazily inside function bodies
  # and only fail with a clear ImportError if invoked without those extras.
  pythonImportsCheck = [ "headroom" ];

  meta = {
    description = "Compresses tool outputs, logs, files and RAG chunks before they reach the LLM";
    homepage = "https://github.com/headroomlabs-ai/headroom";
    changelog = "https://github.com/headroomlabs-ai/headroom/blob/main/CHANGELOG.md";
    license = lib.licenses.asl20;
    mainProgram = "headroom";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
