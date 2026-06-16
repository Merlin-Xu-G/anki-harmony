# Tasks: AnkiHarmony Core

**Input**: Design documents from `specs/001-anki-harmony-core/`

**Prerequisites**: plan.md (required), spec.md (required), phases.md (required)

**Tests**: No automated tests specified in the feature spec. Validation is manual on MatePad Pro per phase gate criteria.

**Organization**: Tasks follow the phased delivery plan (Phase 0 → Phase 3). Within each phase, tasks are ordered by dependency. `[P]` marks tasks that can run in parallel (different files/modules, no blocking dependencies).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- File paths follow the project structure defined in plan.md

## Path Conventions

- **ArkTS frontend**: `entry/src/main/ets/` (pages, components, services, models)
- **Rust backend**: `rust/src/` (bridge/, wrapper/)
- **Resources**: `entry/src/main/resources/`
- **Test fixtures**: `tests/`

---

## Phase 1: Technical Validation Spike (Phase 0 from phases.md)

**Purpose**: Prove the architecture works before building anything. **GATE: If T001 or T002 fail, architecture is not viable — stop and reevaluate.**

**Duration**: 1–2 weeks

- [ ] T001 [US1] Cross-compile `portableanki` for HarmonyOS ARM64 — set up Rust toolchain with `aarch64-unknown-linux-ohos` target, vendoring portableanki in `rust/portableanki/`, verify `cargo build` succeeds in `rust/`
- [ ] T002 [US1] Set up NAPI bridge (Rust → ArkTS) — create `rust/src/bridge/` with a minimal NAPI module, call a Rust function from ArkTS and receive a return value, document the FFI ceremony overhead
- [ ] T003 [US1] Open Anki collection in Rust — implement collection open/close in `rust/src/wrapper/`, load a test `.apkg` from `tests/fixtures/`, list decks and card counts callable from ArkTS via NAPI
- [ ] T004 [US1] Verify FSRS scheduling correctness — compare Rust FSRS output against Anki Desktop for known inputs (5+ test cases), confirm intervals match within tolerance
- [ ] T005 [US2] Prototype M-Pencil drawing with PenEvent API — create a standalone ArkUI page using `PenEvent` API, render pressure-sensitive strokes, measure latency (target: <16ms)
- [ ] T006 [US4] Test AnkiWeb sync handshake — authenticate with test AnkiWeb account, receive sync timestamp and server state, verify protocol compatibility in `rust/src/wrapper/sync.rs`

**Checkpoint**: Phase 0 gate — if T001 (cross-compile) or T002 (NAPI bridge) fail, stop. Architecture needs rethinking (e.g., process-based IPC or pure ArkTS FSRS). Write findings to `specs/001-anki-harmony-core/research.md`.

---

## Phase 2: Foundational (Shared Infrastructure)

**Purpose**: Project scaffold and NAPI bridge layer that ALL user stories depend on.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [ ] T007 Create DevEco Studio project scaffold — initialize HarmonyOS app in `entry/` with correct module structure, `build-profile.json5`, and `.hap` build config; verify build produces installable package
- [ ] T008 [P] Set up Rust workspace — configure `rust/Cargo.toml` with workspace members (bridge, wrapper), set up `aarch64-unknown-linux-ohos` target in `.cargo/config.toml`, wire build into DevEco Studio build pipeline
- [ ] T009 [P] Define ArkTS data models — create models in `entry/src/main/ets/models/` for Deck, Note, Card, NoteType, ReviewSession matching Anki's entity model from spec.md
- [ ] T010 Define NAPI bridge contracts — design the Rust→ArkTS function signatures for all core operations (collection, review queue, sync, import/export) in `specs/001-anki-harmony-core/contracts/bridge-api.md`
- [ ] T011 Implement NAPI bridge: collection operations — open/close `.apkg`, query deck list, card counts, note types in `rust/src/bridge/collection.rs` with corresponding ArkTS bindings
- [ ] T012 Implement NAPI bridge: review queue — get next card, submit answer (rating), get next due date in `rust/src/bridge/review.rs` with FSRS scheduling via `rust/src/wrapper/scheduler.rs`
- [ ] T013 [P] Implement NAPI bridge: import/export — `.apkg` import and export in `rust/src/bridge/io.rs`
- [ ] T014 [P] Set up error handling infrastructure — define error types in `rust/src/bridge/error.rs`, map Rust errors to ArkTS error codes, create error UI component in `entry/src/main/ets/components/`

**Checkpoint**: Foundation ready — NAPI bridge can open collections, serve review queues, and handle errors. User story implementation can begin.

---

## Phase 3: User Story 1 — Review Decks with M-Pencil Drawing (P1) 🎯 MVP

**Goal**: Users can import a deck and review cards with M-Pencil drawing — the core value proposition.

**Independent Test**: Create a deck with 10 cards, review all of them, draw on each card's answer canvas, flip to verify. Completes a full study session.

**FRs covered**: FR-001, FR-002, FR-004, FR-011, FR-014, FR-016

### Implementation for User Story 1

- [ ] T015 [US1] Build card viewer UI — create `entry/src/main/ets/components/CardView/` with ArkUI component that renders card front/back from Anki templates, supporting text, images, and basic HTML
- [ ] T016 [US1] Build M-Pencil drawing canvas — create `entry/src/main/ets/components/DrawingCanvas/` using PenEvent API, pressure-sensitive strokes with variable ink width, palm rejection, clear-on-flip behavior (ephemeral), state cleanup on card transitions (FR-014)
- [ ] T017 [US1] Build review controls — create `entry/src/main/ets/components/ReviewControls/` with card flip gesture/button and 4 rating buttons (Again, Hard, Good, Easy) wired to NAPI review queue (FR-016)
- [ ] T018 [US1] Implement review session service — create `entry/src/main/ets/services/ReviewSession/` managing the review loop state (current deck, queue position, session stats), connecting CardView + DrawingCanvas + ReviewControls into a complete flow
- [ ] T019 [US1] Build deck browser — create `entry/src/main/ets/components/DeckList/` showing all decks with card counts and due counts, tap to start review, deck hierarchy with expand/collapse for sub-decks
- [ ] T020 [US1] Implement .apkg import — wire file picker → NAPI import → deck appears in browser, handle corrupted files gracefully (error per spec edge cases)
- [ ] T021 [US1] Build reviewer page — create `entry/src/main/ets/pages/ReviewerPage.ets` assembling CardView, DrawingCanvas, ReviewControls, and ReviewSession into the full review screen
- [ ] T022 [US1] Build home/deck browser page — create `entry/src/main/ets/pages/DeckBrowserPage.ets` as the app landing screen with deck list, import button, and settings entry point
- [ ] T023 [US1] Wire offline persistence — ensure review progress survives app close/reopen via Anki's SQLite storage (FR-004), verify no data loss on force-quit
- [ ] T024 [US1] Touch input fallback — ensure all review operations work with touch input (no M-Pencil required), per FR-011

**Checkpoint**: MVP complete — installable .hap that lets users import a deck and do a full review session with M-Pencil drawing. Validate SC-001 (20 cards in <5 min), SC-004 (drawing <16ms), SC-006 (import to review in <30s).

---

## Phase 4: User Story 2 — Import and Manage Decks (P1)

**Goal**: Full .apkg import with media, deck browser with search and filtering, deck hierarchy navigation.

**Independent Test**: Import a .apkg file containing multiple decks with images and audio. Verify all decks appear in the browser with correct counts and media.

**FRs covered**: FR-003, FR-007, FR-009

### Implementation for User Story 2

- [ ] T025 [P] [US2] Implement media extraction in Rust — extract images/audio from `.apkg` in `rust/src/bridge/io.rs`, store to app media directory, wire into import flow
- [ ] T026 [P] [US2] Implement image/audio rendering in CardView — extend `entry/src/main/ets/components/CardView/` to render embedded images and play audio clips from card fields (FR-007)
- [ ] T027 [US2] Add deck browser search — implement instant text search across all notes/decks in `entry/src/main/ets/components/DeckList/`, search bar UI with debounce (FR-009)
- [ ] T028 [US2] Add deck hierarchy navigation — extend deck browser to show collapsible sub-deck tree with accurate card counts per node, drill-down into sub-decks

**Checkpoint**: Deck import and management complete — full .apkg support with media, search, and hierarchy. Validate SC-003 (identical rendering to Anki Desktop).

---

## Phase 5: User Story 3 — Create and Edit Cards (P2)

**Goal**: Users can create, edit, and delete notes with configurable templates, including M-Pencil sketch-to-image.

**Independent Test**: Create a new note with front/back template, add text and an image, save it, then review the new card in a session.

**FRs covered**: FR-005, FR-007, FR-008

### Implementation for User Story 3

- [ ] T029 [P] [US3] Implement note type / card template system in Rust — parse Anki card templates, render cards from note fields + template in `rust/src/wrapper/template.rs`
- [ ] T030 [P] [US3] Add MathJax rendering to CardView — integrate MathJax engine in `entry/src/main/ets/components/CardView/` for LaTeX rendering in card templates (FR-008)
- [ ] T031 [US3] Build card editor UI — create `entry/src/main/ets/components/CardEditor/` with multi-field editing, note type selector, preview panel, and M-Pencil sketch input
- [ ] T032 [US3] Implement M-Pencil sketch → image field — drawing in editor canvas saves to card image field, converts to PNG stored in collection media (FR-007)
- [ ] T033 [US3] Wire editor to NAPI — create/update/delete notes via `rust/src/bridge/notes.rs`, regenerate cards on note edit, reflect changes across all generated cards
- [ ] T034 [US3] Build card/note editor page — create `entry/src/main/ets/pages/CardEditorPage.ets` for creating and editing notes, accessed from deck browser and review session

**Checkpoint**: Card creation and editing complete — users can create notes with any supported field type, edit existing notes, and use M-Pencil to sketch into image fields.

---

## Phase 6: User Story 4 — Sync with AnkiWeb (P2)

**Goal**: Full AnkiWeb sync — download/upload collections, conflict resolution, multi-device workflow.

**Independent Test**: Sync a collection from AnkiWeb, study some cards, sync back, verify changes appear on Anki Desktop.

**FRs covered**: FR-006

### Implementation for User Story 4

- [ ] T035 [US4] Implement AnkiWeb auth — create `entry/src/main/ets/services/SyncService/` with login UI, credential storage (HarmonyOS keychain), and session management
- [ ] T036 [US4] Implement sync download — full collection download from AnkiWeb in `rust/src/wrapper/sync.rs`, merge into local collection, handle media download
- [ ] T037 [US4] Implement sync upload — upload local changes to AnkiWeb, handle media upload, apply Anki's standard conflict resolution strategy
- [ ] T038 [US4] Build sync settings and status UI — sync button in deck browser, sync progress indicator, last-sync timestamp, conflict resolution prompts in `entry/src/main/ets/pages/SyncSettingsPage.ets`
- [ ] T039 [US4] Handle sync failure gracefully — network errors preserve local progress (offline-first), retry logic, error messaging per spec edge cases

**Checkpoint**: AnkiWeb sync complete — full bidirectional sync with conflict resolution. Validate SC-005 (byte-for-byte protocol compatibility).

---

## Phase 7: User Story 5 — Study Statistics and Progress Tracking (P3)

**Goal**: Study analytics dashboard with daily counts, retention rate, streak, and forecast.

**Independent Test**: Complete a review session, open statistics, verify today's review count and retention data match the session.

**FRs covered**: FR-010

### Implementation for User Story 5

- [ ] T040 [P] [US5] Implement statistics queries in Rust — daily review counts, retention rates, streak calculation, scheduling forecast in `rust/src/wrapper/stats.rs`
- [ ] T041 [US5] Build statistics dashboard UI — create `entry/src/main/ets/pages/StatsPage.ets` with daily counts, retention rate chart, streak counter, per-deck overview, and scheduling forecast visualization

**Checkpoint**: Statistics complete — users can see study progress and performance trends.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Production-ready quality across all user stories.

- [ ] T042 [P] Implement night mode / dark theme — system-setting-aware theming for all screens (FR-015)
- [ ] T043 [P] Large deck performance optimization — virtual scrolling, lazy loading, background indexing for 50k+ card decks (SC-002: <3s load)
- [ ] T044 [P] Empty and error state handling — graceful UI for all edge cases from spec (corrupted .apkg, empty decks, sync failures, low memory)
- [ ] T045 [P] Onboarding flow — first-launch setup screen, deck import guidance, M-Pencil feature introduction
- [ ] T046 [P] Accessibility basics — screen reader support for all review controls, minimum touch targets (48dp), content descriptions
- [ ] T047 Phone form factor layout — adaptive ArkUI layouts for phone screens (FR-012), touch-only mode for devices without M-Pencil (deferred from v1 but scaffold the responsive hooks)
- [ ] T048 Performance audit — measure and optimize card flip latency (<100ms target), drawing latency, memory usage during review sessions with image-heavy cards

**Checkpoint**: App is polished and ready for AppGallery submission.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Spike)**: No dependencies — start immediately. **GATE: blocks everything if T001 or T002 fail.**
- **Phase 2 (Foundational)**: Depends on Phase 1 gate passing — BLOCKS all user stories
- **Phase 3 (US1 — Review)**: Depends on Phase 2 — first MVP deliverable
- **Phase 4 (US2 — Import/Manage)**: Depends on Phase 2; can start in parallel with Phase 3 if staffed, but sequentially after Phase 3 for solo dev
- **Phase 5 (US3 — Card Editing)**: Depends on Phase 3 (needs review UI context)
- **Phase 6 (US4 — Sync)**: Depends on Phase 3 (needs collection and review infrastructure)
- **Phase 7 (US5 — Statistics)**: Depends on Phase 3 (needs review session data)
- **Phase 8 (Polish)**: Depends on Phases 3–7 (cross-cutting, touches all screens)

### User Story Dependencies

```
Phase 1 (Spike) ──GATE──▶ Phase 2 (Foundation)
                              │
                              ├──▶ Phase 3 (US1 Review) ──▶ Phase 5 (US3 Edit)
                              │         │                           │
                              │         ├──▶ Phase 4 (US2 Import)   │
                              │         │                           │
                              │         ├──▶ Phase 6 (US4 Sync)    │
                              │         │                           │
                              │         └──▶ Phase 7 (US5 Stats)   │
                              │                                     │
                              └─────────────────────────────────────┘
                                                    │
                                              Phase 8 (Polish)
```

### Within Each Phase

- `[P]` tasks can run in parallel (different files/modules)
- Rust backend tasks before ArkTS frontend tasks that depend on them
- Models/types before services, services before UI
- Core implementation before error handling and edge cases

### Parallel Opportunities

- T008, T009 can run in parallel (Rust workspace vs ArkTS models)
- T013, T014 can run in parallel (import/export vs error handling)
- T025, T026 can run in parallel (media extraction vs rendering)
- T029, T030 can run in parallel (template system vs MathJax)
- T040 can start as soon as Phase 3 is complete (stats queries don't need US2-US4)
- T042–T046 can all run in parallel (independent polish tasks)

---

## Implementation Strategy

### Solo Developer (Recommended)

1. **Phase 1**: Spike — prove architecture, write `research.md`
2. **Phase 2**: Foundation — project scaffold + NAPI bridge
3. **Phase 3**: US1 Review — MVP, **STOP and VALIDATE** on device
4. **Phase 4**: US2 Import — complete P1 features, demo-ready
5. **Phase 5**: US3 Edit — card creation
6. **Phase 6**: US4 Sync — AnkiWeb integration
7. **Phase 7**: US5 Stats — study analytics
8. **Phase 8**: Polish — production quality, AppGallery submission

### Risk Mitigation

- **T001/T002 gate** is non-negotiable — do not invest in UI work until Rust compilation and NAPI bridge are proven
- **T005 (M-Pencil prototype)** informs T016 (DrawingCanvas) — keep the prototype code as reference
- **T006 (sync handshake)** validates US4 early — if sync protocol is incompatible, Phase 6 scope changes

---

## Notes

- `[P]` tasks = different files, no dependencies — safe to parallelize
- `[Story]` label maps task to specific user story for traceability
- Tests are manual on-device (MatePad Pro) — no automated test framework specified
- Each phase has a checkpoint — stop and validate before proceeding
- Commit after each task or logical group (per user preference)
- DevEco Studio must be installed before Phase 2 can begin
- v1 targets tablet form factor only — phone layout (T047) is a scaffold, not a full implementation
