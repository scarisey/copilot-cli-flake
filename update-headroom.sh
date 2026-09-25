#!/usr/bin/env bash

CURRENT_VERSION=$(jq -r '.version' headroom-versions.json)
echo "Current version: $CURRENT_VERSION"

PYPI_JSON=$(curl -s https://pypi.org/pypi/headroom-ai/json)
LATEST_VERSION=$(echo "$PYPI_JSON" | jq -r '.info.version')
echo "Latest version:  $LATEST_VERSION"

to_sri() {
  local hex="$1"
  nix hash to-sri --type sha256 "$hex" 2>/dev/null
}

# Extract a field (jq path expression, e.g. ".url" or ".digests.sha256") of the
# wheel whose filename matches the given regex pattern
wheel_field() {
  local pattern="$1"
  local field="$2"
  echo "$PYPI_JSON" | jq -r --arg pattern "$pattern" \
    ".releases[\$ENV.LATEST_VERSION][] | select(.filename | test(\$pattern)) | $field" \
    | head -n1
}

# Check if update is needed
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
  tmpFile=$(mktemp)

  echo "Fetching hashes for all platforms..."
  export LATEST_VERSION
  URL_LINUX_X64=$(wheel_field 'manylinux.*x86_64\.whl$' '.url')
  URL_LINUX_ARM64=$(wheel_field 'manylinux.*aarch64\.whl$' '.url')
  URL_DARWIN_X64=$(wheel_field 'macosx.*x86_64\.whl$' '.url')
  URL_DARWIN_ARM64=$(wheel_field 'macosx.*arm64\.whl$' '.url')

  SHA256_HEX_LINUX_X64=$(wheel_field 'manylinux.*x86_64\.whl$' '.digests.sha256')
  SHA256_HEX_LINUX_ARM64=$(wheel_field 'manylinux.*aarch64\.whl$' '.digests.sha256')
  SHA256_HEX_DARWIN_X64=$(wheel_field 'macosx.*x86_64\.whl$' '.digests.sha256')
  SHA256_HEX_DARWIN_ARM64=$(wheel_field 'macosx.*arm64\.whl$' '.digests.sha256')

  SHA256_LINUX_X64=$(to_sri "$SHA256_HEX_LINUX_X64")
  SHA256_LINUX_ARM64=$(to_sri "$SHA256_HEX_LINUX_ARM64")
  SHA256_DARWIN_X64=$(to_sri "$SHA256_HEX_DARWIN_X64")
  SHA256_DARWIN_ARM64=$(to_sri "$SHA256_HEX_DARWIN_ARM64")

  jq \
    --arg v   "$LATEST_VERSION" \
    --arg lxu "$URL_LINUX_X64" \
    --arg lau "$URL_LINUX_ARM64" \
    --arg dxu "$URL_DARWIN_X64" \
    --arg dau "$URL_DARWIN_ARM64" \
    --arg lx  "$SHA256_LINUX_X64" \
    --arg la  "$SHA256_LINUX_ARM64" \
    --arg dx  "$SHA256_DARWIN_X64" \
    --arg da  "$SHA256_DARWIN_ARM64" \
    '.version=$v | .urlLinux_x64=$lxu | .urlLinux_arm64=$lau | .urlDarwin_x64=$dxu | .urlDarwin_arm64=$dau | .sha256Linux_x64=$lx | .sha256Linux_arm64=$la | .sha256Darwin_x64=$dx | .sha256Darwin_arm64=$da' \
    headroom-versions.json > "$tmpFile"
  cp "$tmpFile" headroom-versions.json
  rm -f "$tmpFile"

  echo "Updated headroom-versions.json:"
  cat headroom-versions.json
else
  echo "No update needed"
fi
