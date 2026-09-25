# GitHub Copilot CLI - Nix Package

A Nix flake that packages the [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) for easy installation on NixOS and with Home Manager.

## Overview

This repository provides a Nix flake that packages the GitHub Copilot CLI, allowing you to easily install and use GitHub Copilot in your terminal on NixOS systems or through Home Manager.
This flake is updated weekly with the last version of Copilot.

It also packages [Headroom](https://github.com/headroomlabs-ai/headroom), the token compressor for LLM applications, as a separate `headroom` output.

## Prerequisites

- Nix with flakes enabled
- A GitHub account with Copilot access
- For Home Manager usage: Home Manager installed and configured

## Quick Start

### Using the Development Shell

The easiest way to try the GitHub Copilot CLI is using the development shell:

```bash
# Clone this repository
git clone <repository-url>

# Enter the development shell
nix develop

# The copilot command should now be available
copilot --help

# 'copilot-hr' is also available: it's 'copilot' transparently wrapped
# through the Headroom proxy for token compression.
copilot-hr --help
```

### Building the Package

To build the package locally:

```bash
nix build
```

The built package will be available in the `result` symlink.

### Headroom (token compressor)

This flake also builds [Headroom](https://github.com/headroomlabs-ai/headroom) as its own package output, using the official prebuilt `headroom-ai` PyPI wheel plus nixpkgs' `ast-grep` for the binary it shells out to (no plain pass-through of a `nixpkgs` package):

```bash
nix build .#headroom
./result/bin/headroom --help
```

It's also included in the default development shell alongside `copilot`. The `proxy` extra (needed for `headroom proxy` / `headroom wrap <tool>`) is packaged too; only ML-only extras (e.g. the Kompress-v2-base prose model, some agent-specific wrappers) are left out and fail with a clear `ImportError` if invoked.

### Copilot CLI module, with optional Headroom wrapping

This flake exposes ready-to-use modules, for NixOS, Home Manager and [devenv](https://devenv.sh), built around a `programs.copilotCli` option namespace (`copilotCli` for devenv):

```nix
# NixOS / Home Manager
{
  imports = [ copilot-cli.nixosModules.default ]; # or homeManagerModules.default
  programs.copilotCli.enable = true;
}
```

```nix
# devenv.nix
{ inputs, ... }: {
  imports = [ inputs.copilot-cli.devenvModules.default ];
  copilotCli.enable = true;
}
```

`enable` alone installs the plain `copilot` command. Enabling the nested `headroom` option additionally (or instead) installs it wrapped through the [Headroom](https://github.com/headroomlabs-ai/headroom) proxy (`headroom wrap copilot`):

```nix
# Only the Headroom-wrapped copilot is installed; running `copilot`
# transparently goes through Headroom.
programs.copilotCli = {
  enable = true;
  headroom.enable = true;
};
```

```nix
# Both are installed side by side: plain `copilot`, and `copilot-hr` wrapped
# with Headroom.
programs.copilotCli = {
  enable = true;
  headroom = {
    enable = true;
    wrapperName = "copilot-hr";
  };
};
```

Options:

| Option                    | Default    | Description                                                            |
| ------------------------- | ---------- | ------------------------------------------------------------------------ |
| `enable`                  | `false`    | Install the GitHub Copilot CLI.                                          |
| `package`                 | this flake's `default` package | The GitHub Copilot CLI package to install.                    |
| `headroom.enable`         | `false`    | Additionally install `copilot` wrapped with Headroom.                    |
| `headroom.package`        | this flake's `headroom` package | The Headroom package used to run the proxy.                  |
| `headroom.wrapperName`    | `"copilot"` | Command name for the wrapper. When `"copilot"` (the default), it *replaces* the plain `copilot` command (only the wrapped binary is installed). Set to e.g. `"copilot-hr"` to install it *alongside* the plain `copilot` command instead. |
| `headroom.port`           | `8787`     | Local port used by the Headroom proxy.                                   |
| `headroom.subscription`   | `false`    | Pass `--subscription` (route via your GitHub Copilot subscription instead of a BYOK provider key). |
| `headroom.extraWrapArgs`  | `[ ]`      | Extra arguments forwarded to `headroom wrap copilot` (e.g. `[ "--backend" "anyllm" ]`). |

The wrapper always resolves the real `copilot` binary first (it prepends the plain package's `bin` directory to `PATH`), so it's safe even when `wrapperName` is `"copilot"` itself — it cannot recurse into itself.

## Installation Methods

All methods below need this flake added as an input first:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    copilot-cli.url = "github:scarisey/copilot-cli-flake";
    # If also using Home Manager:
    home-manager.url = "github:nix-community/home-manager";
  };
  # ...
}
```

### Method 1 (Recommended): NixOS / Home Manager Module

Use the `programs.copilotCli` module described in [Copilot CLI module, with optional Headroom wrapping](#copilot-cli-module-with-optional-headroom-wrapping) above — it handles installation and, optionally, Headroom wrapping for you:

```nix
{
  imports = [ copilot-cli.nixosModules.default ]; # or homeManagerModules.default
  programs.copilotCli.enable = true;
}
```

This works the same way whether Home Manager is used standalone, as a NixOS module (`home-manager.users.<user> = { imports = [ copilot-cli.homeManagerModules.default ]; programs.copilotCli.enable = true; }`), or for devenv (`copilotCli.enable = true` with `devenvModules.default`).

### Method 2: Direct Package Reference

If you don't need the module (e.g. no Headroom wrapping, or you manage packages manually), reference the package output directly:

```nix
# NixOS: environment.systemPackages
# Home Manager: home.packages
[ copilot-cli.packages.${pkgs.system}.default ]
```

### Method 3: One-off Installation with Nix Profile

For a quick, non-declarative installation:

```bash
nix profile install github:scarisey/copilot-cli-flake   # from the flake
nix profile install .                                    # from a local clone
```

## Supported Architectures

This flake supports the following systems:
- `x86_64-linux`
- `aarch64-linux` 
- `x86_64-darwin`
- `aarch64-darwin`

## Authentication and Setup

After installation, you'll need to authenticate with GitHub:

```bash
# Start the authentication process with Github CLI
gh auth login

# Follow the prompts to authenticate with your GitHub account
```

## Usage

Once installed and authenticated, you can use GitHub Copilot CLI:

```bash
# Get help
copilot --help

# Just start interactive mode
copilot

# Execute a prompt in non-interactive mode
copilot -p "Fix the bug in main.js" --allow-all-tools

```

## Development

### Updating the Package

To update to a newer version of the GitHub Copilot CLI:

Use `update.sh` script that will do the following :

1. Update the `version` in `package.nix`
2. Update the `url` and `sha256` in the `fetchurl` call
3. Update the `npmDepsHash`

### Local Development

```bash
# Enter the development shell
nix develop

# Make changes to package.nix or flake.nix

# Test your changes
nix build

# Test the development shell
nix develop --command copilot --help
```

## Troubleshooting

### Flakes Not Enabled

If you get an error about flakes not being enabled, add this to your Nix configuration:

```nix
# /etc/nixos/configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Or for non-NixOS systems, add to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

### Authentication Issues

If you have trouble with authentication:

1. Make sure you have a GitHub account with Copilot access
2. Try logging out and back in: `copilot auth logout` then `copilot auth login`
3. Check your internet connection and GitHub's status

### Package Not Found

If the `copilot` command is not found after installation:

1. Make sure the package is in your PATH
2. Try restarting your shell or sourcing your profile
3. For Home Manager users, ensure you've run `home-manager switch`

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

For more information about GitHub Copilot CLI, visit the [official documentation](https://docs.github.com/en/copilot/github-copilot-in-the-cli).
