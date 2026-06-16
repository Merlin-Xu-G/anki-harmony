// Collection wrapper — open/close Anki collections

use anki::collection::Collection;
use anki::collection::CollectionBuilder;
use anyhow::Result;

/// Handle to an open Anki collection.
/// Wraps rslib's Collection and provides a safe API.
pub struct CollectionHandle {
    _inner: Collection,
}

impl CollectionHandle {
    /// Open an existing .anki2 collection or create a new one.
    pub fn open(collection_path: &str, media_folder: &str) -> Result<Self> {
        let col = CollectionBuilder::new(collection_path)
            .set_media_paths(media_folder, &format!("{}.media.db", collection_path))
            .build()?;
        Ok(Self { _inner: col })
    }

    /// Close the collection gracefully.
    pub fn close(self) -> Result<()> {
        self._inner.close(None)?;
        Ok(())
    }
}
