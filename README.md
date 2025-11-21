# GitHub Copilot CLI - Nix Package

A Nix flake that packages the [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) for easy installation on NixOS and with Home Manager.

## Overview

This repository provides a Nix flake that packages the GitHub Copilot CLI (version 0.0.330), allowing you to easily install and use GitHub Copilot in your terminal on NixOS systems or through Home Manager.

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
```

### Building the Package

To build the package locally:

```bash
nix build
```

The built package will be available in the `result` symlink.

## Installation Methods

### Method 1: NixOS System Configuration

Add this flake to your NixOS system configuration:

```nix
# /etc/nixos/configuration.nix or flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    copilot-cli.url = "github:scarisey/copilot-cli-flake";
  };

  outputs = { self, nixpkgs, copilot-cli, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or your system architecture
      modules = [
        {
          environment.systemPackages = [
            copilot-cli.packages.x86_64-linux.default # Adjust architecture as needed
          ];
        }
        # ... your other modules
      ];
    };
  };
}
```

Then rebuild your system:

```bash
sudo nixos-rebuild switch
```

### Method 2: Home Manager (Standalone)

If you're using Home Manager as a standalone tool:

```nix
# ~/.config/home-manager/home.nix
{ config, pkgs, ... }:

let
  copilot-cli = builtins.getFlake "github:scarisey/copilot-cli-flake";
in
{
  home.packages = [
    copilot-cli.packages.${pkgs.system}.default
  ];

  # Rest of your Home Manager configuration...
}
```

Apply the configuration:

```bash
home-manager switch
```

### Method 3: Home Manager (NixOS Module)

If you're using Home Manager as a NixOS module:

```nix
# /etc/nixos/configuration.nix or your flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    copilot-cli.url = "github:scarisey/copilot-cli-flake";
  };

  outputs = { self, nixpkgs, home-manager, copilot-cli, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.users.yourusername = {
            home.packages = [
              copilot-cli.packages.x86_64-linux.default
            ];
          };
        }
        # ... your other modules
      ];
    };
  };
}
```

### Method 4: Direct Installation with Nix Profile

For a quick one-time installation:

```bash
# Install directly from the flake
nix profile install github:scarisey/copilot-cli-flake

# Or install from a local clone
nix profile install .
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
# Start the authentication process
copilot auth login

# Follow the prompts to authenticate with your GitHub account
```

## Usage

Once installed and authenticated, you can use GitHub Copilot CLI:

```bash
# Get help
copilot --help

# Ask Copilot to explain a command
copilot explain "ls -la"

# Ask Copilot to suggest a command
copilot suggest "find all .js files modified in the last week"

# Use Copilot in chat mode
copilot chat
```

## Development

### Updating the Package

To update to a newer version of the GitHub Copilot CLI:

1. Update the `version` in `package.nix`
2. Update the `url` and `sha256` in the `fetchurl` call
3. Update the `npmDepsHash` (you may need to set it to an empty string first and let Nix tell you the correct hash)

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
