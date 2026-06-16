// Import/Export wrapper — .apkg file operations
//
// Uses Collection's inherent methods import_apkg() and export_apkg().
// Both take protobuf option types from anki_proto.

use anki::import_export::package::{ExportAnkiPackageOptions, ImportAnkiPackageOptions};
use anki::import_export::NoteLog;
use anyhow::Result;
use serde::Serialize;

/// Result of importing an .apkg file.
#[derive(Debug, Clone, Serialize)]
pub struct ImportResult {
    /// Total notes found in the package.
    pub found_notes: u32,
    /// Number of new notes added.
    pub new_count: u32,
    /// Number of existing notes updated.
    pub updated_count: u32,
    /// Number of duplicate notes.
    pub duplicate_count: u32,
}

impl From<NoteLog> for ImportResult {
    fn from(log: NoteLog) -> Self {
        Self {
            found_notes: log.found_notes,
            new_count: log.new.len() as u32,
            updated_count: log.updated.len() as u32,
            duplicate_count: log.duplicate.len() as u32,
        }
    }
}

/// Result of exporting an .apkg file.
#[derive(Debug, Clone, Serialize)]
pub struct ExportResult {
    /// Number of notes exported.
    pub note_count: usize,
}

/// Import an .apkg file into the currently open collection.
///
/// Args:
///   apkg_path: Path to the .apkg file.
///   merge_notetypes: If true, merge notetypes instead of adding new ones.
///   with_scheduling: If true, preserve scheduling info from the package.
pub fn import_apkg(
    apkg_path: &str,
    merge_notetypes: bool,
    with_scheduling: bool,
) -> Result<ImportResult> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        let options = ImportAnkiPackageOptions {
            merge_notetypes,
            update_notes: 0, // IF_NEWER
            update_notetypes: 0,
            with_scheduling,
            with_deck_configs: true,
        };

        let result = col.import_apkg(apkg_path, options)?;
        Ok(ImportResult::from(result.output))
    })
}

/// Export a deck (or the whole collection) as an .apkg file.
///
/// Args:
///   out_path: Where to write the .apkg file.
///   with_scheduling: If true, include scheduling data in the export.
///   with_media: If true, include media files in the export.
///   search: Search filter (empty string = whole collection).
pub fn export_apkg(
    out_path: &str,
    with_scheduling: bool,
    with_media: bool,
    search: &str,
) -> Result<ExportResult> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        let options = ExportAnkiPackageOptions {
            with_scheduling,
            with_deck_configs: true,
            with_media,
            legacy: false,
        };

        let note_count = col.export_apkg(out_path, options, search, None)?;
        Ok(ExportResult { note_count })
    })
}
