#!/bin/bash
# Build the AnkiHarmony NAPI bridge for HarmonyOS ARM64
# Usage: ./build.sh [--release]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Environment setup
source "$HOME/.cargo/env" 2>/dev/null || true

: "${OHOS_NDK_HOME:=$HOME/HarmonyOS_SDK/linux/5.0.0}"
: "${PROTOC:=$(which protoc 2>/dev/null || echo protoc)}"
: "${EXTRA_FTL_ROOT:=$SCRIPT_DIR/vendor/anki/ftl/extra}"

export OHOS_NDK_HOME
export CC_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang"
export CXX_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang++"
export AR_aarch64_unknown_linux_ohos="$OHOS_NDK_HOME/llvm/bin/llvm-ar"
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_OHOS_LINKER="$OHOS_NDK_HOME/llvm/bin/aarch64-unknown-linux-ohos-clang"
export PROTOC
export EXTRA_FTL_ROOT

PROFILE="release"
if [[ "${1:-}" == "--debug" ]]; then
    PROFILE="debug"
    shift
fi

echo "=== Building anki-harmony-bridge ($PROFILE) for HarmonyOS ARM64 ==="
echo "  OHOS_NDK_HOME: $OHOS_NDK_HOME"
echo "  PROTOC: $PROTOC"
echo "  EXTRA_FTL_ROOT: $EXTRA_FTL_ROOT"
echo ""

if [[ "$PROFILE" == "release" ]]; then
    cargo build -p anki-harmony-bridge --target aarch64-unknown-linux-ohos --release "$@"
else
    cargo build -p anki-harmony-bridge --target aarch64-unknown-linux-ohos "$@"
fi

echo ""
echo "=== Build complete ==="
echo "Output: target/aarch64-unknown-linux-ohos/$PROFILE/libanki_harmony_bridge.so"
