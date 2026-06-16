// Review wrapper — card scheduling and review queue management

/// Rating for a card answer, matching Anki's standard ratings.
#[derive(Debug, Clone, Copy, serde::Serialize, serde::Deserialize)]
#[repr(u8)]
pub enum Rating {
    Again = 1,
    Hard = 2,
    Good = 3,
    Easy = 4,
}

/// Information about the next card to review.
#[derive(Debug, Clone, serde::Serialize)]
pub struct NextCard {
    pub card_id: u64,
    pub note_id: u64,
    pub question: String,
    pub answer: String,
    pub new_count: u32,
    pub learning_count: u32,
    pub review_count: u32,
}
