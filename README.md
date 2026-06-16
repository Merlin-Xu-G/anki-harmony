# AnkiHarmony

Flashcards on HarmonyOS with M-Pencil support. A native ArkTS/ArkUI port of
[Anki](https://apps.ankiweb.net/) for HarmonyOS NEXT, built on Anki's portable
Rust backend (rslib/portableanki).

## Overview

AnkiHarmony provides the full Anki spaced repetition experience on HarmonyOS
tablets, with M-Pencil as a first-class input method. Draw answers with
pressure-sensitive ink, study with FSRS scheduling, and sync seamlessly with
AnkiWeb.

## Architecture

```
┌─────────────────────────────────┐
│     ArkTS / ArkUI Layer          │  ← Native HarmonyOS UI
│   Card viewer, editor, browser   │
│   M-Pencil drawing engine        │
└──────────────┬──────────────────┘
               │  NAPI Bridge
┌──────────────▼──────────────────┐
│     Rust Core (portableanki)     │  ← Anki's battle-tested backend
│   FSRS scheduling, sync, storage  │
└─────────────────────────────────┘
```

## v1 Scope (Tablet-First)

- Deck review with FSRS spaced repetition
- M-Pencil drawing canvas (ephemeral, like AnkiDroid whiteboard)
- .apkg deck import/export
- Card creation and editing
- AnkiWeb sync
- Deck browser with search
- Night mode

Phone support planned for v1.1 (touch-only mode).

## Status

🚧 **In Specification** — Currently in the spec-kit workflow.

## Contributing

See [Contributing Guide](CONTRIBUTING.md) (TODO).

## License

AGPL-3.0 (consistent with Anki's license).
