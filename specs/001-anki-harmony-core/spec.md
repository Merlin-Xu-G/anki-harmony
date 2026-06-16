# Feature Specification: AnkiHarmony Core

**Feature Branch**: `001-anki-harmony-core`

**Created**: 2025-06-17

**Status**: Draft

**Input**: Native HarmonyOS flashcard app that replicates AnkiDroid functionality with M-Pencil first-class support, built on Anki's portable Rust backend.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review Decks with M-Pencil Drawing (Priority: P1)

A student opens AnkiHarmony on their MatePad, selects a deck, and reviews
flashcards using the spaced repetition algorithm. During review, they use M-Pencil
to draw or write their answer directly on the card canvas before flipping to
check correctness. The drawing supports pressure-sensitive strokes, palm
rejection, and variable ink width.

**Why this priority**: This is the core value proposition — deck review with
enhanced stylus input. Without this, nothing else matters. It delivers
immediate value: study with drawing on HarmonyOS.

**Independent Test**: Create a deck with 10 cards, review all of them, draw on
each card's answer canvas, flip to verify. Completes a full study session.

**Acceptance Scenarios**:

1. **Given** a deck with cards, **When** the user starts a review session, **Then**
   cards are shown in the order determined by the FSRS scheduling algorithm
2. **Given** a card is shown, **When** the user draws on the canvas with M-Pencil,
   **Then** pressure-sensitive ink strokes are rendered with variable width
3. **Given** the user has drawn an answer, **When** they flip the card, **Then**
   the drawing clears and the correct answer is revealed
4. **Given** the user rates difficulty, **When** they select a rating, **Then**
   the card's next review date is calculated by FSRS and the next card appears
5. **Given** the review session ends, **When** progress is synced, **Then** the
   study data is persisted and can be synced with AnkiWeb

---

### User Story 2 - Import and Manage Decks (Priority: P1)

A user imports a .apkg deck file (downloaded from AnkiWeb or shared by a
classmate). The deck appears in their deck browser with correct card counts,
note types, and media. They can browse cards, search, and organize decks into
sub-decks.

**Why this priority**: Without deck import, users have no content to study.
This is equally critical as the review engine itself. Together with Story 1,
these form the minimum viable product.

**Independent Test**: Import a .apkg file containing multiple decks with images
and audio. Verify all decks appear in the browser with correct counts and media.

**Acceptance Scenarios**:

1. **Given** a .apkg file, **When** the user imports it, **Then** all decks,
   notes, cards, and media are extracted and available in the app
2. **Given** the deck browser, **When** the user searches for text, **Then**
   matching cards are displayed instantly
3. **Given** a deck with sub-decks, **When** the user navigates the deck tree,
   **Then** hierarchy is preserved and card counts are accurate

---

### User Story 3 - Create and Edit Cards (Priority: P2)

A user creates new cards or edits existing ones. They use card templates that
support text, images, audio, and MathJax. When editing on a tablet, they can
use M-Pencil to sketch directly into image fields on the card.

**Why this priority**: Essential for personal knowledge management. Users need
to create their own content beyond imported decks. Can be delivered after core
review works.

**Independent Test**: Create a new note with front/back template, add text and
an image, save it, then review the new card in a session.

**Acceptance Scenarios**:

1. **Given** the card editor, **When** the user creates a new note, **Then**
   fields are populated and a card is generated from the selected template
2. **Given** a card with an image field, **When** the user draws with M-Pencil,
   **Then** the drawing is saved as a card image
3. **Given** a note type with multiple fields, **When** the user edits a note,
   **Then** changes are reflected across all cards generated from that note

---

### User Story 4 - Sync with AnkiWeb (Priority: P2)

A user signs into their AnkiWeb account. Their decks, cards, and study progress
synchronize across AnkiHarmony, Anki Desktop, and AnkiDroid. They can study on
their phone with AnkiDroid during commute, then continue on their MatePad with
AnkiHarmony at home.

**Why this priority**: Sync is critical for users with multi-device workflows,
but the app has standalone value without it. Deliver after core review and
import are stable.

**Independent Test**: Sync a collection from AnkiWeb, study some cards, sync
back, then verify the changes appear on Anki Desktop.

**Acceptance Scenarios**:

1. **Given** valid AnkiWeb credentials, **When** the user syncs, **Then** the
   full collection is downloaded and available for review
2. **Given** local changes, **When** the user syncs, **Then** changes are
   uploaded to AnkiWeb without conflicts
3. **Given** a sync conflict, **When** both sides have changes, **Then**
   the system resolves using Anki's standard conflict resolution strategy

---

### User Story 5 - Study Statistics and Progress Tracking (Priority: P3)

A user views their study statistics — cards reviewed today, retention rate,
streak counter, and scheduling forecast. They can see which decks need
attention and how their memory performance trends over time.

**Why this priority**: Helpful for motivation and study optimization, but not
required for the core study loop. Nice-to-have after the essential features are
solid.

**Independent Test**: Complete a review session, then open statistics and verify
today's review count and retention data match the session.

**Acceptance Scenarios**:

1. **Given** completed reviews, **When** the user opens statistics, **Then**
   accurate counts for today's reviews, retention, and streaks are displayed
2. **Given** multiple decks, **When** the user views deck overview, **Then**
   due counts and recent activity per deck are shown

---

### Edge Cases

- What happens when a .apkg file is corrupted or contains unsupported media
  formats?
- How does the system handle very large decks (100,000+ cards) on device with
  limited storage?
- What happens when the user flips a card before drawing an answer — is the
  empty drawing state handled gracefully?
- How does M-Pencil drawing behave when switching between cards rapidly (state
  cleanup)?
- What happens when AnkiWeb sync fails due to network issues — is local
  progress preserved?
- How does the app behave when transitioning between phone (no M-Pencil) and
  tablet (with M-Pencil) on the same account?
- What happens when the device runs low on memory during a review session with
  image-heavy cards?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display flashcards for review using the FSRS spaced
  repetition scheduling algorithm
- **FR-002**: System MUST provide a pressure-sensitive drawing canvas using
  HarmonyOS PenEvent API for M-Pencil input during card review
- **FR-003**: System MUST import .apkg deck files preserving decks, notes,
  cards, and embedded media
- **FR-004**: System MUST persist study progress locally using SQLite storage
  compatible with Anki's collection format
- **FR-005**: System MUST allow users to create, edit, and delete notes and
  cards using configurable note types and templates
- **FR-006**: System MUST synchronize collections with AnkiWeb using the
  standard Anki sync protocol
- **FR-007**: System MUST support text, images, and audio content in card
  fields
- **FR-008**: System MUST support MathJax rendering in card templates
- **FR-009**: System MUST provide a deck browser with search, filtering, and
  deck hierarchy navigation
- **FR-010**: System MUST display study statistics including daily review
  counts, retention rates, and scheduling forecasts
- **FR-011**: System MUST support both touch input and M-Pencil input
  interchangeably — M-Pencil must never be required for core functionality
- **FR-012**: System MUST support phone and tablet form factors with adaptive
  layouts via ArkUI responsive design
- **FR-013**: System MUST export collections to .apkg format for backup and
  sharing
- **FR-014**: System MUST handle M-Pencil drawing state cleanup on card
  transitions without memory leaks
- **FR-015**: System MUST support night mode / dark theme following
  HarmonyOS system settings
- **FR-016**: System MUST provide card rating buttons (Again, Hard, Good, Easy)
  with configurable intervals

### Key Entities

- **Collection**: The root data container holding all decks, notes, and
  scheduling data. One per user account.
- **Deck**: A named group of cards with optional sub-decks forming a hierarchy.
  Carries its own configuration (options group).
- **Note**: A data record consisting of typed fields (text, images, audio) mapped
  to a note type. Can generate multiple cards.
- **Card**: A single reviewable unit generated from a note and a card template.
  Carries scheduling state (due, interval, ease factor, stability).
- **Note Type**: A template defining the fields and card templates for generating
  cards from notes. Maps to Anki's "model" concept.
- **Drawing Canvas**: A temporary per-card drawing surface for M-Pencil input.
  Not persisted across reviews unless explicitly saved to a note field.
- **Review Session**: A transient context tracking the current deck being
  reviewed, cards seen, and pending queue state.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete a full review session of 20 cards in under 5
  minutes, including M-Pencil drawing on each card
- **SC-002**: A deck with 50,000 cards loads and becomes reviewable within 3
  seconds of opening
- **SC-003**: Imported .apkg files render identically to the same deck viewed
  in Anki Desktop — no formatting, media, or scheduling data loss
- **SC-004**: M-Pencil drawing latency is under 16ms (perceived as
  instantaneous) with at least 256 levels of pressure sensitivity
- **SC-005**: AnkiWeb sync completes successfully with byte-for-byte protocol
  compatibility, verified against the Anki Desktop sync test suite
- **SC-006**: Users can import a deck and start reviewing within 30 seconds
  of first launching the app (excluding account setup)

## Clarifications

### Session 2025-06-17

- Q: Should M-Pencil drawings persist across reviews? → A: Ephemeral by default (cleared on card flip, like AnkiDroid whiteboard). Users can explicitly export drawings to card image fields.
- Q: Should v1 target tablets first or both phone and tablet? → A: Tablet-first for v1 (M-Pencil differentiator). Phone support deferred to v1.1 with touch-only mode.
- Q: Should the app be offline-first or online-first? → A: Offline-first. Full functionality without internet; sync when available (classic Anki model).

## Assumptions

- Users have HarmonyOS NEXT (v5+) installed on their device (tablet form factor for v1; phone support in v1.1)
- Users have a Huawei account for AppGallery distribution (no sideloading
  assumed as primary distribution method)
- The Anki portable Rust backend (rslib) can be compiled for HarmonyOS ARM64
  targets — this is a critical technical risk that must be validated early
- The HarmonyOS NAPI (Native API) bridge can expose Rust functions to ArkTS
  with acceptable performance overhead
- DevEco Studio is available for development and debugging
- M-Pencil hardware is available on target devices (MatePad Pro series)
  — phone users will use touch-only mode
- AnkiWeb sync protocol changes are infrequent and well-documented
- The FSRS algorithm implementation in portableanki is the current stable
  version
