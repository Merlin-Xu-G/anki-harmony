// AnkiHarmony NAPI Bridge — exposes Rust backend to ArkTS
// This cdylib is loaded by HarmonyOS at runtime.

#[macro_use]
extern crate napi_derive;

/// Get the Anki version string.
#[napi]
pub fn get_anki_version() -> String {
    // Will be wired to the wrapper once collection ops are implemented
    "0.1.0-alpha".to_string()
}
