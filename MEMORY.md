# Afterthought — Decision Log

Personal-memory macOS app (remake of the Windows original). Captures notes + screen
snapshots in opt-in sessions, OCRs/embeds them, and lets you query your past as
coherent episodic memories. Reviewed against the `swiftui-pro` skill conventions.

## Decisions

### 2026-06-07 — Architecture (interview)
**Decided:**
- **Platform:** macOS only. Background screen capture of other apps is desktop-only; iOS sandboxes it away.
- **Distribution:** App Store *aspirational*. Build sandbox-compatible from day one (data in container, proper entitlements). Capture engine kept modular so distribution choice never forces a rewrite.
- **App shape:** Menu-bar item (quick capture, start/stop, status) + main window (timeline/search/query).
- **Capture model:** Opt-in, session/interval-based + manual quick-capture. NOT always-on surveillance — this is what keeps it App-Store-plausible.
- **Data model:** `Session` (time-bounded creative burst) groups `Entry` items (note/screenshot/audio/video). Entries may be standalone.
- **Persistence:** SwiftData index (Session/Entry) + raw media as files on disk in the app container.
- **Brain:** On-device Apple Foundation Models (macOS 26) for summary/query. Free, private, offline. Optional Claude API path reserved for heavy cross-time reasoning later.
- **Retrieval:** Session-centric **episodic** retrieval — embed session summaries (and standalone notes), brute-force cosine over `[Float]` in Swift. No vector DB at personal scale.
- **Scaffold:** XcodeGen (`project.yml`) → `.xcodeproj`. Reproducible, no Xcode-wizard step.
- **Milestone 1 scope:** notes + interval screenshots through the full capture→OCR→embed→store→episodic-query loop. Audio/video in milestone 2.

**Rejected & why:**
- *Always-on continuous capture (Rewind-style)* — privacy + App Store review risk; David wants intentional, session-based capture.
- *Flat entry-level chunk RAG* — David flagged it as dated; session-level episodic retrieval is more coherent and fits the "real memories" goal.
- *Semantic/RAG built fully upfront* — deferred the heavy machinery; build the vertical slice first.
- *Core Data / blobs-in-DB* — SwiftData + files-on-disk is the modern idiomatic choice and keeps the store small.

## Open items / to verify
- **Embedding API:** confirm `NLContextualEmbedding` vs Foundation Models for on-device sentence embeddings on macOS 26 before wiring (milestone 1c). Not asserting the API from memory.
- **Foundation Models API surface:** verify method signatures against current docs at implementation time.
- App Store viability of the passive-capture engine remains an open question; manual capture is safe regardless.

## Status
- **1a DONE** — XcodeGen project, SwiftData models (Session/Entry/EntryKind), AppState, menu-bar quick-note + start/stop session, timeline window with search. Builds clean against macOS 26.5 SDK.
- **1b NEXT** — ScreenCaptureKit interval screenshots + Vision OCR + Screen Recording permission flow.
- **1c** — on-device embeddings, session summaries, episodic query UI.
