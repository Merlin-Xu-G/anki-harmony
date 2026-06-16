// Collection wrapper — open/close and query Anki collections
//
// Uses Collection's inherent methods directly. The DecksService trait
// is NOT used — we call col.deck_tree() directly.

use crate::error::AnkiHarmonyError;
use anki::collection::CollectionBuilder;
use anki_proto::decks::DeckTreeNode;
use anyhow::Result;
use serde::Serialize;

/// Simplified deck info for the NAPI bridge.
#[derive(Debug, Clone, Serialize)]
pub struct DeckInfo {
    pub id: i64,
    pub name: String,
    pub level: u32,
    pub collapsed: bool,
    pub review_count: u32,
    pub learn_count: u32,
    pub new_count: u32,
    pub children: Vec<DeckInfo>,
}

impl From<&DeckTreeNode> for DeckInfo {
    fn from(node: &DeckTreeNode) -> Self {
        Self {
            id: node.deck_id,
            name: node.name.clone(),
            level: node.level,
            collapsed: node.collapsed,
            review_count: node.review_count,
            learn_count: node.learn_count,
            new_count: node.new_count,
            children: node.children.iter().map(DeckInfo::from).collect(),
        }
    }
}

/// Open a .anki2 collection file.
pub fn open_collection(col_path: &str, media_folder: &str) -> Result<()> {
    let state = crate::global_state();
    let mut guard = state.lock();

    if guard.collection.is_some() {
        return Err(AnkiHarmonyError::CollectionAlreadyOpen.into());
    }

    let col = CollectionBuilder::new(col_path)
        .set_media_paths(media_folder, &format!("{}.media.db", col_path))
        .build()?;

    guard.collection = Some(col);
    Ok(())
}

/// Close the currently open collection.
pub fn close_collection() -> Result<()> {
    let state = crate::global_state();
    let mut guard = state.lock();

    if let Some(col) = guard.collection.take() {
        col.close(None)?;
    }
    Ok(())
}

/// Check if a collection is currently open.
pub fn is_collection_open() -> bool {
    let state = crate::global_state();
    let locked = state.lock();
    locked.collection.is_some()
}

/// Get the deck tree (all decks with counts).
pub fn get_deck_tree() -> Result<Vec<DeckInfo>> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        // deck_tree(timestamp: Option<TimestampSecs>) — inherent method on Collection
        let tree = col.deck_tree(None)?;
        Ok(tree.children.iter().map(DeckInfo::from).collect())
    })
}

/// Get the bridge version string.
pub fn get_anki_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
