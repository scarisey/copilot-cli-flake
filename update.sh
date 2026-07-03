#!/usr/bin/env bash

CURRENT_VERSION=$(jq -r '.version' versions.json)
echo "Current version: $CURRENT_VERSION"
LATEST_VERSION=$(npm view @github/copilot version)
echo "Latest version:  $LATEST_VERSION"

fetch_sri() {
  local url="$1"
  local raw
  raw=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null)
  nix hash to-sri --type sha256 "$raw" 2>/dev/null
}

# Check if update is needed
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
  tmpFile=$(mktemp)

  echo "Fetching hashes for all platforms..."
  SHA256_LINUX_X64=$(fetch_sri   "https://registry.npmjs.org/@github/copilot-linux-x64/-/copilot-linux-x64-${LATEST_VERSION}.tgz")
  SHA256_LINUX_ARM64=$(fetch_sri "https://registry.npmjs.org/@github/copilot-linux-arm64/-/copilot-linux-arm64-${LATEST_VERSION}.tgz")
  SHA256_DARWIN_X64=$(fetch_sri  "https://registry.npmjs.org/@github/copilot-darwin-x64/-/copilot-darwin-x64-${LATEST_VERSION}.tgz")
  SHA256_DARWIN_ARM64=$(fetch_sri "https://registry.npmjs.org/@github/copilot-darwin-arm64/-/copilot-darwin-arm64-${LATEST_VERSION}.tgz")

  jq \
    --arg v   "$LATEST_VERSION" \
    --arg lx  "$SHA256_LINUX_X64" \
    --arg la  "$SHA256_LINUX_ARM64" \
    --arg dx  "$SHA256_DARWIN_X64" \
    --arg da  "$SHA256_DARWIN_ARM64" \
    '.version=$v | .sha256Linux_x64=$lx | .sha256Linux_arm64=$la | .sha256Darwin_x64=$dx | .sha256Darwin_arm64=$da' \
    versions.json > "$tmpFile"
  cp "$tmpFile" versions.json
  rm -f "$tmpFile"

  echo "Updated versions.json:"
  cat versions.json
else
  echo "No update needed"
fi
