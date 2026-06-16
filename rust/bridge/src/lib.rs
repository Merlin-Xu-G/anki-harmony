// AnkiHarmony NAPI Bridge — exposes Rust backend to ArkTS
// This cdylib is loaded by HarmonyOS at runtime.

#[macro_use]
extern crate napi_derive;

use anki_harmony_wrapper::collection::{self, DeckInfo};
use anki_harmony_wrapper::error::AnkiHarmonyError;
use anki_harmony_wrapper::import_export as io_mod;
use anki_harmony_wrapper::review::{
    self as review_mod, AnswerResult, NextCardInfo, QueueCounts, Rating,
};

// --- Collection Operations ---

#[napi]
/// Open a .anki2 collection file.
pub fn open_collection(col_path: String, media_folder: String) -> napi::Result<()> {
    collection::open_collection(&col_path, &media_folder).map_err(to_napi_error)
}

#[napi]
/// Close the currently open collection.
pub fn close_collection() -> napi::Result<()> {
    collection::close_collection().map_err(to_napi_error)
}

#[napi]
/// Check if a collection is currently open.
pub fn is_collection_open() -> bool {
    collection::is_collection_open()
}

// --- Deck Operations ---

#[napi(object)]
pub struct JsDeckInfo {
    pub id: i64,
    pub name: String,
    pub level: u32,
    pub collapsed: bool,
    pub review_count: u32,
    pub learn_count: u32,
    pub new_count: u32,
    pub children: Vec<JsDeckInfo>,
}

impl From<DeckInfo> for JsDeckInfo {
    fn from(d: DeckInfo) -> Self {
        Self {
            id: d.id,
            name: d.name,
            level: d.level,
            collapsed: d.collapsed,
            review_count: d.review_count,
            learn_count: d.learn_count,
            new_count: d.new_count,
            children: d.children.into_iter().map(JsDeckInfo::from).collect(),
        }
    }
}

#[napi]
/// Get all decks in the collection as a tree.
pub fn get_decks() -> napi::Result<Vec<JsDeckInfo>> {
    collection::get_deck_tree()
        .map(|decks| decks.into_iter().map(JsDeckInfo::from).collect())
        .map_err(to_napi_error)
}

// --- Review Operations ---

#[napi(object)]
pub struct JsNextCard {
    pub card_id: i64,
    pub note_id: i64,
    pub deck_id: i64,
    pub template_idx: u32,
    pub question_html: String,
    pub answer_html: String,
    pub css: String,
    pub new_count: u32,
    pub learn_count: u32,
    pub review_count: u32,
    /// JSON scheduling states — pass back to answer_card.
    pub states_json: String,
}

impl From<NextCardInfo> for JsNextCard {
    fn from(c: NextCardInfo) -> Self {
        Self {
            card_id: c.card_id,
            note_id: c.note_id,
            deck_id: c.deck_id,
            template_idx: c.template_idx,
            question_html: c.question_html,
            answer_html: c.answer_html,
            css: c.css,
            new_count: c.new_count,
            learn_count: c.learn_count,
            review_count: c.review_count,
            states_json: c.states_json,
        }
    }
}

#[napi(object)]
pub struct JsQueueCounts {
    pub new_count: u32,
    pub learning_count: u32,
    pub review_count: u32,
}

impl From<QueueCounts> for JsQueueCounts {
    fn from(c: QueueCounts) -> Self {
        Self {
            new_count: c.new,
            learning_count: c.learning,
            review_count: c.review,
        }
    }
}

#[napi(object)]
pub struct JsAnswerResult {
    pub card_id: i64,
}

impl From<AnswerResult> for JsAnswerResult {
    fn from(r: AnswerResult) -> Self {
        Self { card_id: r.card_id }
    }
}

#[napi]
/// Get the next card due for review. Returns null if no cards available.
pub fn get_next_card() -> napi::Result<Option<JsNextCard>> {
    review_mod::get_next_card()
        .map(|opt| opt.map(JsNextCard::from))
        .map_err(to_napi_error)
}

#[napi]
/// Answer a card. Rating: 1=Again, 2=Hard, 3=Good, 4=Easy.
/// states_json must come from the previously fetched JsNextCard.
pub fn answer_card(
    card_id: i64,
    rating: u8,
    millis_taken: u32,
    states_json: String,
) -> napi::Result<JsAnswerResult> {
    let rating = match rating {
        1 => Rating::Again,
        2 => Rating::Hard,
        3 => Rating::Good,
        4 => Rating::Easy,
        _ => return Err(napi::Error::from_reason("Invalid rating: must be 1-4")),
    };

    review_mod::answer_card(card_id, rating, millis_taken, &states_json)
        .map(JsAnswerResult::from)
        .map_err(to_napi_error)
}

#[napi]
/// Get current queue counts (new, learning, review).
pub fn get_queue_counts() -> napi::Result<JsQueueCounts> {
    review_mod::get_queue_counts()
        .map(JsQueueCounts::from)
        .map_err(to_napi_error)
}

// --- Import/Export Operations ---

#[napi(object)]
pub struct JsImportResult {
    pub found_notes: u32,
    pub new_count: u32,
    pub updated_count: u32,
    pub duplicate_count: u32,
}

impl From<io_mod::ImportResult> for JsImportResult {
    fn from(r: io_mod::ImportResult) -> Self {
        Self {
            found_notes: r.found_notes,
            new_count: r.new_count,
            updated_count: r.updated_count,
            duplicate_count: r.duplicate_count,
        }
    }
}

#[napi(object)]
pub struct JsExportResult {
    pub note_count: u32,
}

impl From<io_mod::ExportResult> for JsExportResult {
    fn from(r: io_mod::ExportResult) -> Self {
        Self {
            note_count: r.note_count as u32,
        }
    }
}

#[napi]
/// Import an .apkg file into the currently open collection.
pub fn import_apkg(
    apkg_path: String,
    merge_notetypes: bool,
    with_scheduling: bool,
) -> napi::Result<JsImportResult> {
    io_mod::import_apkg(&apkg_path, merge_notetypes, with_scheduling)
        .map(JsImportResult::from)
        .map_err(to_napi_error)
}

#[napi]
/// Export a deck (or the whole collection) as an .apkg file.
/// search: empty string = whole collection.
pub fn export_apkg(
    out_path: String,
    with_scheduling: bool,
    with_media: bool,
    search: String,
) -> napi::Result<JsExportResult> {
    io_mod::export_apkg(&out_path, with_scheduling, with_media, &search)
        .map(JsExportResult::from)
        .map_err(to_napi_error)
}

// --- Version ---

#[napi]
/// Get the bridge version string.
pub fn get_bridge_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

// --- Helpers ---

fn to_napi_error(err: anyhow::Error) -> napi::Error {
    let message = err.to_string();
    let code = if let Some(anki_err) = err.downcast_ref::<AnkiHarmonyError>() {
        match anki_err {
            AnkiHarmonyError::CollectionNotOpen => "COLLECTION_NOT_OPEN",
            AnkiHarmonyError::CollectionAlreadyOpen => "COLLECTION_ALREADY_OPEN",
            AnkiHarmonyError::InvalidPath(_) => "INVALID_PATH",
            AnkiHarmonyError::Io(_) => "IO_ERROR",
            AnkiHarmonyError::Anki(_) => "ANKI_ERROR",
        }
    } else {
        "UNKNOWN"
    };
    napi::Error::from_reason(format!("[{}] {}", code, message))
}
