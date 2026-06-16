# Implementation Plan: AnkiHarmony Core

**Branch**: `001-anki-harmony-core` | **Date**: 2025-06-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-anki-harmony-core/spec.md`

## Summary

Build a native HarmonyOS tablet flashcard app replicating AnkiDroid's core
functionality with M-Pencil first-class support. Architecture: ArkTS/ArkUI
frontend + Anki's portable Rust backend (rslib) bridged via NAPI. v1 targets
tablets only; phone support deferred to v1.1.

## Technical Context

**Language/Version**: ArkTS (HarmonyOS NEXT SDK), Rust 1.75+

**Primary Dependencies**:
- `rslib` / `portableanki` (Anki's Rust backend — FSRS, sync, storage)
- HarmonyOS NEXT SDK (ArkUI, PenEvent API, NAPI)
- DevEco Studio (IDE, build tooling)

**Storage**: SQLite (via Rust backend, Anki's existing storage model)

**Testing**: `cargo test` (Rust backend), ArkTS unit tests (frontend),
manual integration testing on MatePad Pro

**Target Platform**: HarmonyOS NEXT v5+, tablet form factor (MatePad Pro
series, ARM64)

**Project Type**: Mobile app (HarmonyOS native)

**Performance Goals**: Card flip <100ms, drawing latency <16ms, 50k-card
deck loads in <3s

**Constraints**: Offline-first, .hap package format, must sync with AnkiWeb
protocol byte-for-byte, ephemeral drawing canvas

**Scale/Scope**: Single app, ~15-20 ArkTS UI screens, NAPI bridge layer,
Rust compilation target for HarmonyOS ARM64

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Native HarmonyOS Experience | ✅ Pass | ArkTS/ArkUI throughout, no web wrappers |
| II. Core Reuse via Rust Backend | ⚠️ Risk | Must validate cross-compilation for HarmonyOS ARM64 in Phase 0 |
| III. M-Pencil as First-Class Input | ✅ Pass | PenEvent API for drawing, touch fallback for all features |
| IV. AnkiWeb Compatibility | ⚠️ Risk | Must validate sync protocol compatibility in Phase 0 |
| V. Progressive Delivery | ✅ Pass | Phase 0 spike, then 4 incremental delivery phases |

**Gate decision**: Proceed to Phase 0. Principles II and IV carry technical
risk that must be resolved before committing to Phase 2+.

## Project Structure

### Documentation (this feature)

```text
specs/001-anki-harmony-core/
├── spec.md              # Feature specification (done)
├── plan.md              # This file
├── research.md          # Phase 0 output (technical validation)
├── data-model.md        # Phase 1 output (entity relationships)
├── contracts/           # Phase 1 output (NAPI bridge contracts)
└── tasks.md             # Phase 2 output (from /speckit-tasks)
```

### Source Code (repository root)

```text
anki-harmony/
├── entry/                          # HarmonyOS app entry point
│   └── src/main/
│       ├── ets/
│       │   ├── pages/              # UI pages (reviewer, browser, editor, stats)
│       │   ├── components/        # Reusable ArkUI components
│       │   │   ├── CardView/      # Card rendering with template engine
│       │   │   ├── DrawingCanvas/ # M-Pencil drawing engine
│       │   │   ├── DeckList/      # Deck browser
│       │   │   ├── ReviewControls/# Rating buttons, card flip
│       │   │   └── CardEditor/    # Note creation/editing UI
│       │   ├── services/          # App-level services
│       │   │   ├── ReviewSession/ # Review queue management
│       │   │   └── SyncService/   # AnkiWeb sync orchestration
│       │   ├── models/            # ArkTS data models
│       │   └── utils/             # Helpers, formatters
│       └── resources/             # App resources, assets
├── rust/                          # Rust backend
│   ├── Cargo.toml
│   ├── src/
│   │   ├── bridge/                # NAPI bindings (ArkTS ↔ Rust FFI)
│   │   └── wrapper/               # Thin wrappers over portableanki
│   └── portableanki/              # Git submodule or vendored rslib
├── docs/                          # User-facing documentation
├── tests/                         # Integration test fixtures (.apkg samples)
├── specs/                         # Spec-kit artifacts
└── README.md
```

**Structure Decision**: Flat `entry/` + `rust/` layout. The HarmonyOS app
entry follows DevEco Studio conventions. The Rust backend lives in `rust/` as
a separate compilation unit, bridged to ArkTS via NAPI. This keeps the portable
Anki backend isolated and potentially reusable (constitution principle II).

## Complexity Tracking

No constitution violations requiring justification at this time. Phase 0
may surface constraints that require amendments.
