// Error types for the wrapper layer.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum AnkiHarmonyError {
    #[error("Collection not open")]
    CollectionNotOpen,

    #[error("Collection already open")]
    CollectionAlreadyOpen,

    #[error("Invalid collection path: {0}")]
    InvalidPath(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Anki error: {0}")]
    Anki(String),
}

impl From<anki::error::AnkiError> for AnkiHarmonyError {
    fn from(e: anki::error::AnkiError) -> Self {
        AnkiHarmonyError::Anki(e.to_string())
    }
}
