// ArkTS data models for AnkiHarmony
// These mirror the Rust types exposed via NAPI bridge.
// Bridge types (for NAPI interop) are in common/BridgeContract.ets.
// These are higher-level domain models used by the UI layer.

/** Deck information — matches NAPI JsDeckInfo shape. */
export interface DeckInfo {
  id: number;
  name: string;
  level: number;
  collapsed: boolean;
  reviewCount: number;
  learnCount: number;
  newCount: number;
  children: DeckInfo[];
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

/** Counts of cards in each queue — matches NAPI JsQueueCounts shape. */
export interface QueueCounts {
  newCount: number;
  learningCount: number;
  reviewCount: number;
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
