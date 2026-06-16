// Review wrapper — card scheduling and review queue management
//
// Uses Collection's inherent methods (get_next_card, answer_card, render_existing_card).
// SchedulingStates are serialized to/from JSON using serde derives
// (added via vendor patches to rslib state types).

use crate::error::AnkiHarmonyError;
use anki::scheduler::answering::{CardAnswer, Rating as AnkiRating};
use anki::scheduler::queue::QueuedCard;
use anki::scheduler::states::SchedulingStates;
use anyhow::Result;
use serde::Serialize;

/// Rating for a card answer, matching Anki's standard ratings.
#[derive(Debug, Clone, Copy, serde::Serialize, serde::Deserialize, PartialEq, Eq)]
#[repr(u8)]
pub enum Rating {
    Again = 1,
    Hard = 2,
    Good = 3,
    Easy = 4,
}

impl From<Rating> for AnkiRating {
    fn from(r: Rating) -> Self {
        match r {
            Rating::Again => AnkiRating::Again,
            Rating::Hard => AnkiRating::Hard,
            Rating::Good => AnkiRating::Good,
            Rating::Easy => AnkiRating::Easy,
        }
    }
}

/// Information about the next card to review.
#[derive(Debug, Clone, Serialize)]
pub struct NextCardInfo {
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
    /// JSON-serialized SchedulingStates — pass back to answer_card.
    pub states_json: String,
}

/// Result of answering a card.
#[derive(Debug, Clone, Serialize)]
pub struct AnswerResult {
    pub card_id: i64,
}

/// Counts of cards in each queue.
#[derive(Debug, Clone, Serialize)]
pub struct QueueCounts {
    pub new: u32,
    pub learning: u32,
    pub review: u32,
}

/// Extract card info from a QueuedCard.
fn extract_card_info(col: &mut anki::collection::Collection, qc: &QueuedCard) -> Result<NextCardInfo> {
    let card = &qc.card;
    let cid = card.id();

    // Render both sides
    let rendered = col.render_existing_card(cid, false, false)?;

    Ok(NextCardInfo {
        card_id: cid.0,
        note_id: card.note_id().0,
        deck_id: card.deck_id().0,
        template_idx: card.template_idx() as u32,
        question_html: rendered.question().to_string(),
        answer_html: rendered.answer().to_string(),
        css: rendered.css,
        new_count: 0,  // will be filled by get_next_cards
        learn_count: 0,
        review_count: 0,
        states_json: serde_json::to_string(&qc.states)
            .map_err(|e| AnkiHarmonyError::Anki(e.to_string()))?,
    })
}

/// Get the next card due for review.
pub fn get_next_card() -> Result<Option<NextCardInfo>> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        let qc = col.get_next_card()?;
        match qc {
            Some(card) => {
                let mut info = extract_card_info(col, &card)?;
                // Get counts from the queue
                let queued = col.get_queued_cards(0, false)?;
                info.new_count = queued.new_count as u32;
                info.learn_count = queued.learning_count as u32;
                info.review_count = queued.review_count as u32;
                Ok(Some(info))
            }
            None => Ok(None),
        }
    })
}

/// Answer a card. The states_json comes from the previously fetched NextCardInfo.
pub fn answer_card(
    card_id: i64,
    rating: Rating,
    millis_taken: u32,
    states_json: &str,
) -> Result<AnswerResult> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        let states: SchedulingStates = serde_json::from_str(states_json)
            .map_err(|e| AnkiHarmonyError::Anki(format!("invalid states JSON: {}", e)))?;

        // Build current and new states from the SchedulingStates
        let current_state = states.current.clone();
        let new_state = match rating {
            Rating::Again => states.again,
            Rating::Hard => states.hard,
            Rating::Good => states.good,
            Rating::Easy => states.easy,
        };

        let mut answer = CardAnswer {
            card_id: anki::prelude::CardId(card_id),
            current_state,
            new_state,
            rating: rating.into(),
            answered_at: anki::timestamp::TimestampMillis::now(),
            milliseconds_taken: millis_taken.min(60 * 1000),
            custom_data: None,
        };

        col.answer_card(&mut answer)?;

        Ok(AnswerResult { card_id })
    })
}

/// Get queue counts (new, learning, review).
pub fn get_queue_counts() -> Result<QueueCounts> {
    let state = crate::global_state();
    let mut guard = state.lock();

    guard.with_collection(|col| {
        let queued = col.get_queued_cards(0, false)?;
        Ok(QueueCounts {
            new: queued.new_count as u32,
            learning: queued.learning_count as u32,
            review: queued.review_count as u32,
        })
    })
}
