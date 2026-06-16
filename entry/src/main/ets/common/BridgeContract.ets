/**
 * NAPI Bridge Contract — AnkiHarmony
 *
 * This file defines the expected interface between the Rust NAPI bridge
 * (libanki_harmony_bridge.so) and the ArkTS frontend.
 *
 * All async functions return Promises. Errors are thrown as strings
 * formatted as "[CODE] message" where CODE is one of:
 *   COLLECTION_NOT_OPEN, COLLECTION_ALREADY_OPEN, INVALID_PATH,
 *   IO_ERROR, ANKI_ERROR, UNKNOWN
 */

// --- Data Types ---

/** Deck information returned by getDecks(). */
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

/** Next card due for review. */
export interface NextCard {
  cardId: number;
  noteId: number;
  deckId: number;
  templateIdx: number;
  questionHtml: string;
  answerHtml: string;
  css: string;
  newCount: number;
  learnCount: number;
  reviewCount: number;
  /** JSON scheduling states — must be passed back to answerCard(). */
  statesJson: string;
}

/** Queue counts (new, learning, review). */
export interface QueueCounts {
  newCount: number;
  learningCount: number;
  reviewCount: number;
}

/** Result of answering a card. */
export interface AnswerResult {
  cardId: number;
}

/** Result of importing an .apkg file. */
export interface ImportResult {
  foundNotes: number;
  newCount: number;
  updatedCount: number;
  duplicateCount: number;
}

/** Result of exporting an .apkg file. */
export interface ExportResult {
  noteCount: number;
}

// --- Error Handling ---

export enum AnkiErrorCode {
  Unknown = 'UNKNOWN',
  CollectionNotOpen = 'COLLECTION_NOT_OPEN',
  CollectionAlreadyOpen = 'COLLECTION_ALREADY_OPEN',
  InvalidPath = 'INVALID_PATH',
  IoError = 'IO_ERROR',
  AnkiError = 'ANKI_ERROR',
}

export class AnkiError extends Error {
  code: AnkiErrorCode;
  constructor(code: AnkiErrorCode, message: string) {
    super(`[${code}] ${message}`);
    this.code = code;
    this.name = 'AnkiError';
  }
}

// --- Bridge Interface ---

/**
 * The actual NAPI bridge interface (libanki_harmony_bridge.so).
 *
 * In ArkTS, load via: import bridge from 'libanki_harmony_bridge.so';
 * Then call functions directly.
 */
export interface IAnkiBridge {
  // --- Collection ---
  openCollection(colPath: string, mediaFolder: string): Promise<void>;
  closeCollection(): Promise<void>;
  isCollectionOpen(): boolean;

  // --- Decks ---
  getDecks(): Promise<DeckInfo[]>;

  // --- Review ---
  getNextCard(): Promise<NextCard | null>;
  /**
   * Answer a card.
   * @param cardId  Card ID from getNextCard()
   * @param rating  1=Again, 2=Hard, 3=Good, 4=Easy
   * @param millisTaken  Time spent on the card in ms
   * @param statesJson  Scheduling states JSON from getNextCard()
   */
  answerCard(cardId: number, rating: number, millisTaken: number, statesJson: string): Promise<AnswerResult>;
  getQueueCounts(): Promise<QueueCounts>;

  // --- Import/Export ---
  /**
   * Import an .apkg file into the collection.
   * @param apkgPath  Path to the .apkg file.
   * @param mergeNotetypes  If true, merge notetypes instead of adding new ones.
   * @param withScheduling  If true, preserve scheduling info from the package.
   */
  importApkg(apkgPath: string, mergeNotetypes: boolean, withScheduling: boolean): Promise<ImportResult>;
  /**
   * Export a deck (or whole collection) as .apkg.
   * @param outPath  Where to write the .apkg file.
   * @param withScheduling  Include scheduling data.
   * @param withMedia  Include media files.
   * @param search  Search filter (empty = whole collection).
   */
  exportApkg(outPath: string, withScheduling: boolean, withMedia: boolean, search: string): Promise<ExportResult>;

  // --- Version ---
  getBridgeVersion(): string;
}
