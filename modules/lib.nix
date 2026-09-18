{ lib }:
{
  # Builds a small wrapper executable that starts (or reuses) the Headroom
  # local proxy and launches GitHub Copilot CLI through it, via
  # `headroom wrap copilot`.
  #
  # The wrapper prepends `copilotPackage`'s bin directory to PATH before
  # exec-ing headroom. `headroom wrap copilot` resolves the real `copilot`
  # binary with a plain `shutil.which("copilot")`, so this guarantees it
  # finds the real CLI first even when `wrapperName` is itself "copilot"
  # (i.e. when this wrapper replaces `copilot` on the user's PATH) — it
  # cannot recurse into itself.
  mkWrapper =
    {
      pkgs,
      copilotPackage,
      headroomPackage,
      wrapperName,
      port,
      subscription,
      extraWrapArgs,
    }:
    pkgs.writeShellScriptBin wrapperName ''
      export PATH="${lib.makeBinPath [ copilotPackage ]}:$PATH"
      exec "${headroomPackage}/bin/headroom" wrap copilot \
        --port ${toString port} \
        ${lib.optionalString subscription "--subscription"} \
        ${lib.escapeShellArgs extraWrapArgs} \
        -- "$@"
    '';

  # Shared option set used by the NixOS, Home Manager and devenv modules.
  mkOptions =
    { lib, pkgs }:
    {
      enable = lib.mkEnableOption "wrapping GitHub Copilot CLI with the Headroom token compressor";

      copilotPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../package.nix { };
        defaultText = lib.literalExpression "pkgs.callPackage ../package.nix { }";
        description = "The GitHub Copilot CLI package to wrap.";
      };

      headroomPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../headroom.nix { };
        defaultText = lib.literalExpression "pkgs.callPackage ../headroom.nix { }";
        description = "The Headroom package used to compress/proxy requests.";
      };

      wrapperName = lib.mkOption {
        type = lib.types.str;
        default = "copilot";
        description = ''
          Name of the command installed on PATH. Defaults to `copilot`, so it
          transparently replaces the plain GitHub Copilot CLI binary with the
          Headroom-wrapped one. Set to something else (e.g. `copilot-hr`) to
          install it alongside the unwrapped `copilot`.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Local port used by the Headroom proxy.";
      };

      subscription = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass `--subscription` to `headroom wrap copilot`, routing requests
          through your GitHub Copilot subscription instead of a BYOK provider
          key.
        '';
      };

      extraWrapArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--backend"
          "anyllm"
          "--anyllm-provider"
          "groq"
        ];
        description = "Extra arguments forwarded to `headroom wrap copilot` before the `--` separator.";
      };
    };
}
