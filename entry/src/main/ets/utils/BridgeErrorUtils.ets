// Error parsing utility for AnkiHarmony
//
// Bridge errors come as strings: "[CODE] message"
// where CODE is one of the AnkiErrorCode enum values.
// This utility parses them into structured error objects.

import { AnkiErrorCode, AnkiError } from '../common/BridgeContract';

/** Parsed error from the bridge. */
export interface BridgeErrorInfo {
  code: AnkiErrorCode;
  message: string;
  /** User-friendly description for display. */
  displayMessage: string;
  /** Whether the user can retry the action. */
  retryable: boolean;
}

/** User-facing descriptions for each error code. */
const ERROR_DESCRIPTIONS: Record<AnkiErrorCode, string> = {
  [AnkiErrorCode.CollectionNotOpen]: 'No collection is open. Please open a collection first.',
  [AnkiErrorCode.CollectionAlreadyOpen]: 'A collection is already open. Close it before opening another.',
  [AnkiErrorCode.InvalidPath]: 'The file path is invalid or the file does not exist.',
  [AnkiErrorCode.IoError]: 'A file system error occurred. Check your storage permissions.',
  [AnkiErrorCode.AnkiError]: 'An error occurred in the Anki engine.',
  [AnkiErrorCode.Unknown]: 'An unknown error occurred.',
};

/** Error codes where retrying might help. */
const RETRYABLE_CODES: Set<AnkiErrorCode> = new Set([
  AnkiErrorCode.IoError,
  AnkiErrorCode.AnkiError,
  AnkiErrorCode.Unknown,
]);

/**
 * Parse a bridge error string into a structured BridgeErrorInfo.
 *
 * Input: "[COLLECTION_NOT_OPEN] Collection not open"
 * Output: { code, message, displayMessage, retryable }
 */
export function parseBridgeError(error: string | Error): BridgeErrorInfo {
  const msg = error instanceof Error ? error.message : error;
  const match = msg.match(/^\[([A-Z_]+)\]\s*(.*)/);

  if (match) {
    const code = match[1] as AnkiErrorCode;
    const detail = match[2];
    return {
      code,
      message: detail,
      displayMessage: ERROR_DESCRIPTIONS[code] || ERROR_DESCRIPTIONS[AnkiErrorCode.Unknown],
      retryable: RETRYABLE_CODES.has(code),
    };
  }

  // No code prefix — unknown error
  return {
    code: AnkiErrorCode.Unknown,
    message: msg,
    displayMessage: ERROR_DESCRIPTIONS[AnkiErrorCode.Unknown],
    retryable: true,
  };
}

/**
 * Create an AnkiError from a code and message (for throwing).
 */
export function createAnkiError(code: AnkiErrorCode, message: string): AnkiError {
  return new AnkiError(code, message);
}

/**
 * Check if an error is a specific AnkiError code.
 */
export function isAnkiError(error: unknown, code: AnkiErrorCode): boolean {
  if (error instanceof AnkiError) {
    return error.code === code;
  }
  if (typeof error === 'string') {
    return error.startsWith(`[${code}]`);
  }
  return false;
}
