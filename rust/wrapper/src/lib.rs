// AnkiHarmony Wrapper — thin Rust wrapper over rslib's public API
//
// Uses the service traits (DecksService, SchedulerService, CardRenderingService,
// ImportExportService) defined in anki::services to interact with Collection.
// These traits use protobuf types (anki_proto) as inputs/outputs.
//
// Our simple JSON-friendly types (DeckInfo, NextCardInfo, etc.) convert
// to/from protobuf at this boundary.

pub mod collection;
pub mod error;
pub mod import_export;
pub mod review;

use anyhow::Result;
use parking_lot::Mutex;
use std::sync::Arc;

/// Global state accessible from the NAPI bridge.
pub struct AppState {
    collection: Option<anki::collection::Collection>,
}

impl AppState {
    pub fn new() -> Self {
        Self { collection: None }
    }

    /// Execute a closure with a mutable reference to the open collection.
    pub fn with_collection<F, T>(&mut self, f: F) -> Result<T>
    where
        F: FnOnce(&mut anki::collection::Collection) -> Result<T>,
    {
        match &mut self.collection {
            Some(col) => f(col),
            None => Err(error::AnkiHarmonyError::CollectionNotOpen.into()),
        }
    }
}

/// Global singleton — initialized once when the .so is loaded.
static STATE: once_cell::sync::Lazy<Arc<Mutex<AppState>>> =
    once_cell::sync::Lazy::new(|| Arc::new(Mutex::new(AppState::new())));

/// Get a clone of the global state Arc.
pub fn global_state() -> Arc<Mutex<AppState>> {
    STATE.clone()
}
