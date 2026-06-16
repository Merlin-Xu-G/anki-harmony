// ArkTS data models for AnkiHarmony
// These mirror the Rust types in wrapper/ and are exposed via NAPI bridge.

/** A deck containing cards. */
export interface DeckInfo {
  id: number;
  name: string;
  description: string;
  cardCount: number;
  newCount: number;
  learningCount: number;
  reviewCount: number;
}

/** A note (the content behind flashcards). */
export interface NoteInfo {
  id: number;
  fieldValues: string[];
  tags: string[];
  notetypeId: number;
  modTime: number;
}

/** A card (one side of a review). */
export interface CardInfo {
  id: number;
  noteId: number;
  deckId: number;
  notetypeId: number;
  ord: number; // which template
  interval: number; // days
  due: number;
  reps: number;
  lapses: number;
  easeFactor: number; // percentage (e.g. 250 = 2.5x)
}

/** Rating for answering a card. */
export enum Rating {
  Again = 1,
  Hard = 2,
  Good = 3,
  Easy = 4,
}

/** The next card to review. */
export interface NextCard {
  card: CardInfo;
  note: NoteInfo;
  question: string;
  answer: string;
  counts: QueueCounts;
}

/** Counts of cards in each queue. */
export interface QueueCounts {
  new: number;
  learning: number;
  review: number;
}

/** Sync status. */
export interface SyncStatus {
  lastSync: number; // timestamp ms
  required: SyncRequired;
  progress?: SyncProgress;
}

export enum SyncRequired {
  No = 0,
  FullSync = 1,
  NormalSync = 2,
}

export interface SyncProgress {
  phase: string;
  current: number;
  total: number;
}

/** Statistics for a deck. */
export interface DeckStats {
  totalCards: number;
  newCards: number;
  learningCards: number;
  reviewCards: number;
  matureCards: number;
  dueToday: number;
  retention: number; // percentage
  averageEase: number;
  totalReviews: number;
}
