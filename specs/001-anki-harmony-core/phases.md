# Phased Delivery Plan

## Phase 0: Technical Validation Spike (Risk Reduction)

**Goal**: Prove the architecture works before building anything.

**Duration**: 1-2 weeks

### Tasks

| # | Task | Success Criteria | Risk |
|---|------|-----------------|------|
| 0.1 | Cross-compile `portableanki` for HarmonyOS ARM64 | `cargo build --target aarch64-unknown-linux-ohos` succeeds | HIGH — unknown toolchain support |
| 0.2 | Set up NAPI bridge (Rust → ArkTS) | Call a Rust function from ArkTS, receive return value | HIGH — NAPI maturity on HarmonyOS |
| 0.3 | Open an Anki collection in Rust, read decks/cards | Load a test `.apkg`, list decks and card counts from ArkTS | MEDIUM |
| 0.4 | Verify FSRS scheduling returns correct intervals | Compare Rust FSRS output against Anki Desktop for known inputs | LOW |
| 0.5 | Prototype M-Pencil drawing with PenEvent API | Pressure-sensitive strokes render at <16ms latency | MEDIUM |
| 0.6 | Test AnkiWeb sync handshake | Authenticate with test account, receive sync timestamp | HIGH — protocol compatibility |

**Gate**: If 0.1 or 0.2 fail, the architecture is not viable and must be
rethought (e.g., process-based IPC instead of NAPI, or pure ArkTS
reimplementation of core algorithms).

---

## Phase 1: Minimum Viable Reviewer (P1 Core)

**Goal**: Users can import a deck and review cards with M-Pencil drawing.

**Duration**: 3-4 weeks

### Tasks

| # | Task | Success Criteria |
|---|------|-----------------|
| 1.1 | DevEco Studio project scaffold | Build produces installable .hap |
| 1.2 | Rust NAPI bridge: collection open/close | Open `.apkg` from ArkTS, query deck list |
| 1.3 | Rust NAPI bridge: review queue | Get next card, submit answer, get next due date |
| 1.4 | Card viewer UI (ArkUI) | Renders front/back of cards with template support |
| 1.5 | M-Pencil drawing canvas component | Pressure-sensitive drawing, clear on flip |
| 1.6 | Review controls (flip + rating buttons) | Full review loop: show → draw → flip → rate → next |
| 1.7 | Deck browser (list view) | Shows all decks with card counts, tap to start review |
| 1.8 | .apkg import | File picker → import → deck appears in browser |
| 1.9 | Offline storage persistence | Close app, reopen, review progress preserved |

**Deliverable**: Installable .hap that lets users import a deck and do a full
review session with M-Pencil drawing.

---

## Phase 2: Card Management + Sync (P2)

**Goal**: Users can create/edit cards and sync with AnkiWeb.

**Duration**: 3-4 weeks

### Tasks

| # | Task | Success Criteria |
|---|------|-----------------|
| 2.1 | Note type / card template system | Parse and render Anki card templates |
| 2.2 | Card editor UI | Create/edit notes with text, images, MathJax preview |
| 2.3 | M-Pencil sketch → image field | Draw in editor, save as card image |
| 2.4 | Deck browser search + filtering | Instant text search across all notes |
| 2.5 | AnkiWeb auth + sync (download) | Full collection sync from AnkiWeb |
| 2.6 | AnkiWeb sync (upload) | Local changes sync back to AnkiWeb |
| 2.7 | Conflict resolution | Standard Anki conflict strategy applied correctly |
| 2.8 | .apkg export | Share decks via .apkg files |

**Deliverable**: Full card creation, editing, and AnkiWeb sync.

---

## Phase 3: Polish + Statistics (P3)

**Goal**: Production-ready quality with study analytics.

**Duration**: 2-3 weeks

### Tasks

| # | Task | Success Criteria |
|---|------|-----------------|
| 3.1 | Night mode / dark theme | Follows system setting, all screens themed |
| 3.2 | Study statistics dashboard | Daily counts, retention rate, streak, forecast |
| 3.3 | Large deck performance optimization | 50k-card deck loads in <3s |
| 3.4 | Empty/error state handling | Graceful UI for all edge cases from spec |
| 3.5 | Onboarding flow | First-launch setup, deck import guidance |
| 3.6 | Accessibility basics | Screen reader support, minimum touch targets |

**Deliverable**: Polished, user-ready app ready for AppGallery submission.

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Rust cannot compile for HarmonyOS ARM64 | Medium | Critical | Phase 0 spike. Fallback: process-based IPC or pure ArkTS FSRS |
| NAPI bridge performance overhead | Medium | High | Phase 0 benchmark. Fallback: batched calls, shared memory |
| AnkiWeb sync protocol breaks compatibility | Low | High | Phase 0 handshake test. Monitor Anki changelogs |
| DevEco Studio tooling immaturity | Medium | Medium | Early adoption. Report issues to Huawei |
| M-Pencil API limitations | Low | Medium | Phase 0 prototype. Fallback: Canvas-based drawing |

---

## Timeline Summary

```
Phase 0 (Spike)       ████                    ~2 weeks
Phase 1 (Reviewer)         ██████████          ~4 weeks
Phase 2 (Manage+Sync)                ██████████  ~4 weeks
Phase 3 (Polish)                             ██████  ~3 weeks
                                               ──────
                                        Total: ~13 weeks
```

**Note**: Phases 1-3 assume Phase 0 gate passes. If Phase 0 reveals blockers,
timeline will be adjusted based on findings.
