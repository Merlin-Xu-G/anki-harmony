#!/bin/bash
# Vendor the anki rslib source and de-workspace it for use in our project.
# Usage: ./vendor.sh [--tag <tag>] [--source <local-anki-path>]
#
# By default, uses the anki source at /tmp/anki-source (tag 25.09.4).
# Run this after cloning the repo to populate rust/vendor/anki/

set -euo pipefill

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="$SCRIPT_DIR/vendor/anki"
FTL_EXTRA_DIR="$VENDOR_DIR/ftl/extra"

TAG="25.09.4"
LOCAL_SOURCE=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --source) LOCAL_SOURCE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Get source
if [[ -n "$LOCAL_SOURCE" && -d "$LOCAL_SOURCE" ]]; then
  echo "Using local source: $LOCAL_SOURCE"
  SRC="$LOCAL_SOURCE"
elif [[ -d "/tmp/anki-source" ]]; then
  echo "Using cached source: /tmp/anki-source"
  SRC="/tmp/anki-source"
else
  echo "Cloning anki at tag $TAG..."
  SRC="/tmp/anki-source"
  git clone --depth 1 --branch "$TAG" https://github.com/ankitects/anki.git "$SRC"
  cd "$SRC"
  git submodule update --init ftl/core-repo ftl/qt-repo
  # Generate out/ directory (needs pyenv/ninja or use pre-generated)
  echo "Note: You may need to run the anki build system to generate out/descriptors.bin"
fi

# Clean and copy
rm -rf "$VENDOR_DIR"
mkdir -p "$VENDOR_DIR"

for item in rslib proto; do
  cp -r "$SRC/$item" "$VENDOR_DIR/$item"
  echo "Copied: $item"
done

for item in ftl/core ftl/core-repo out; do
  mkdir -p "$(dirname "$VENDOR_DIR/$item")"
  cp -r "$SRC/$item" "$VENDOR_DIR/$item"
  echo "Copied: $item"
done

mkdir -p "$VENDOR_DIR/.cargo"
cp "$SRC/.cargo/config.toml" "$VENDOR_DIR/.cargo/config.toml"

# Create empty extra FTL dir (HarmonyOS doesn't use Qt translations)
mkdir -p "$FTL_EXTRA_DIR"

# Create .version file
if [[ -f "$SRC/.version" ]]; then
  cp "$SRC/.version" "$VENDOR_DIR/.version"
  echo "Created: .version"
else
  echo "$TAG" > "$VENDOR_DIR/.version"
  echo "Created: .version (from tag)"
fi

echo ""
echo "=== Vendoring complete ==="
echo "Vendor directory: $VENDOR_DIR"
echo ""
echo "IMPORTANT: You must now run the de-workspace patch:"
echo "  python3 scripts/devendor.py"
