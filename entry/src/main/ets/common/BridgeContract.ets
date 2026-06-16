/**
 * NAPI Bridge Contract
 *
 * This file defines the expected interface between the Rust NAPI bridge
 * (libanki_harmony_bridge.so) and the ArkTS frontend.
 *
 * All functions return Promises (async). Errors are thrown as
 * AnkiError with a numeric code and message string.
 */

/** Error codes from the Rust bridge. */
export enum AnkiErrorCode {
  // General (0-99)
  Unknown = 0,
  CollectionNotOpen = 1,
  CollectionAlreadyOpen = 2,
  InvalidPath = 3,
  IoError = 4,

  // Collection operations (100-199)
  CollectionOpenFailed = 100,
  CollectionCorrupt = 101,
  CollectionTooNew = 102,

  // Review operations (200-299)
  NoCardAvailable = 200,
  InvalidRating = 201,

  // Sync operations (300-399)
  SyncAuthFailed = 300,
  SyncConflict = 301,
  SyncNetworkError = 302,

  // Import/Export (400-499)
  ImportFailed = 400,
  InvalidApkg = 401,
  ExportFailed = 402,
}

/** Bridge error thrown on failure. */
export class AnkiError extends Error {
  code: AnkiErrorCode;
  constructor(code: AnkiErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = 'AnkiError';
  }
}

/**
 * Collection operations
 */
export interface ICollectionBridge {
  /** Open a .anki2 collection file. */
  openCollection(colPath: string, mediaFolder: string): Promise<void>;

  /** Close the currently open collection. */
  closeCollection(): Promise<void>;

  /** Check if a collection is currently open. */
  isCollectionOpen(): boolean;
}

/**
 * Deck operations
 */
export interface IDeckBridge {
  /** Get all decks in the collection. */
  getDecks(): Promise<DeckInfo[]>;

  /** Get statistics for a specific deck. */
  getDeckStats(deckId: number): Promise<DeckStats>;
}

/**
 * Review operations
 */
export interface IReviewBridge {
  /** Get the next card due for review. Returns null if no cards available. */
  getNextCard(deckId?: number): Promise<NextCard | null>;

  /** Answer the current card. Returns the updated card info. */
  answerCard(cardId: number, rating: Rating): Promise<CardInfo>;

  /** Get current queue counts. */
  getQueueCounts(deckId?: number): Promise<QueueCounts>;
}

/**
 * Import/Export operations
 */
export interface IImportExportBridge {
  /** Import an .apkg file into the collection. */
  importApkg(apkgPath: string): Promise<ImportResult>;

  /** Export a deck as .apkg. */
  exportDeck(deckId: number, outputPath: string): Promise<void>;
}

/** Result of an import operation. */
export interface ImportResult {
  newNotes: number;
  newCards: number;
  updatedNotes: number;
  updatedCards: number;
  duplicates: number;
}

/**
 * Sync operations
 */
export interface ISyncBridge {
  /** Check if sync is needed. */
  getSyncStatus(host: string, username: string): Promise<SyncStatus>;

  /** Perform full or normal sync. */
  sync(host: string, username: string, password: string): Promise<void>;
}

/**
 * Combined bridge interface (what the .so actually exports)
 */
export type IAnkiBridge = ICollectionBridge & IDeckBridge & IReviewBridge &
  IImportExportBridge & ISyncBridge;
