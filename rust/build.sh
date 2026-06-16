#!/usr/bin/env bash
# Build the AnkiHarmony NAPI bridge for HarmonyOS ARM64
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Environment setup
export OHOS_NDK_HOME="${OHOS_NDK_HOME:-$HOME/HarmonyOS_SDK/linux/5.0.0}"
export CC_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang"
export CXX_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang++"
export AR_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/llvm-ar"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_OHOS_LINKER="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang"

# Protobuf compiler
export PROTOC="${PROTOC:-$(which protoc)}"

# FTL translation root (skip Qt FTL, only core)
export EXTRA_FTL_ROOT="$SCRIPT_DIR/vendor/anki/ftl/extra"

TARGET="aarch64-unknown-linux-ohos"
PROFILE="${1:-release}"
CRATE="anki-harmony-bridge"

echo "=== Building $CRATE for $TARGET ($PROFILE) ==="
cargo build -p "$CRATE" --target "$TARGET" --$PROFILE

SO_PATH="target/$TARGET/$PROFILE/libanki_harmony_bridge.so"
if [ -f "$SO_PATH" ]; then
    SIZE=$(du -h "$SO_PATH" | cut -f1)
    echo "=== Build succeeded: $SO_PATH ($SIZE) ==="
else
    echo "ERROR: $SO_PATH not found" >&2
    exit 1
fi
