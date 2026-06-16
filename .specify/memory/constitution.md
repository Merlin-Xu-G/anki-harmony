<!--
Sync Impact Report
- Version change: N/A → 1.0.0
- Modified principles: N/A (initial creation)
- Added sections: Core Principles, Technology Constraints, Development Workflow, Governance
- Removed sections: N/A
- Templates requiring updates: ✅ spec-template.md (no changes needed), ✅ plan-template.md (no changes needed), ✅ tasks-template.md (no changes needed)
- Follow-up TODOs: None
-->

# AnkiHarmony Constitution

## Core Principles

### I. Native HarmonyOS Experience
Every feature MUST be implemented as a native HarmonyOS application using ArkUI and
ArkTS. No web-wrapped or cross-platform framework ports. The app MUST feel like it
belongs on HarmonyOS — following system design guidelines, using native components,
and leveraging platform capabilities (distributed features, M-Pencil, multi-window).

### II. Core Reuse via Rust Backend
Anki's portable Rust backend (rslib/portableanki) MUST be reused for all
scheduling, sync, storage, and collection management logic. No reimplementation
of core Anki algorithms. The frontend (ArkTS) communicates with the Rust backend
through a thin bridge layer. This ensures algorithmic correctness, sync
compatibility with AnkiWeb, and data format interoperability with existing Anki
desktop/mobile clients.

### III. M-Pencil as First-Class Input
Stylus interaction MUST be a first-class citizen, not an afterthought. Drawing,
handwriting, and annotation features MUST leverage HarmonyOS's PenEvent API with
pressure sensitivity, palm rejection, and system-level stylus integration. Touch
input MUST work equally well for all features — M-Pencil enhances, never gates,
core functionality.

### IV. AnkiWeb Compatibility
The app MUST sync seamlessly with AnkiWeb using the same protocol as AnkiDroid
and Anki Desktop. Users MUST be able to create cards on any Anki client and
review them on AnkiHarmony without data loss or formatting degradation. Import
and export of .apkg files MUST be fully supported.

### V. Progressive Delivery
Ship the smallest viable slice first: deck review with basic M-Pencil drawing.
Each subsequent release MUST be independently testable and deliverable. No
monolithic "version 1.0" that requires everything to be complete before users see
value.

## Technology Constraints

- Target platform: HarmonyOS NEXT (v5+) on phone and tablet form factors
- Language: ArkTS (frontend), Rust (backend via portableanki)
- UI framework: ArkUI (declarative, component-based)
- App package format: .hap (HarmonyOS Ability Package)
- Data storage: SQLite via Rust backend (consistent with Anki's storage model)
- Minimum supported HarmonyOS API level: to be determined during planning

## Development Workflow

- All work follows the spec-kit workflow: specify → clarify → plan → tasks →
  implement
- Every code change gets its own commit
- Specifications MUST be approved before implementation begins
- Code review required before merging to main

## Governance

- This constitution defines non-negotiable project principles
- All specifications and implementation plans MUST comply with these principles
- Amendments require documentation and version bump
- When in doubt, refer back to these principles — they are the source of truth

**Version**: 1.0.0 | **Ratified**: 2025-06-17 | **Last Amended**: 2025-06-17
