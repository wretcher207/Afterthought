# Afterthought — Session Handoff 2026-06-08

## Overall Goal
Ship Afterthought as a macOS personal-memory app: intentional capture → on-device intelligence → episodic retrieval. Milestone 1 is the vertical slice (notes + screenshots through the full loop).

## Work Completed This Session

### 1c: On-device embeddings + semantic search (committed, pushed)
- **Verified NLEmbedding API surface** against macOS 26.5 SDK via standalone spike (`spike_embedding.swift`). Confirmed 512-dim `[Double]` vectors, `distance(between:and:distanceType:)` Swift API, 2-70ms latency. Rejected `NLContextualEmbedding` (subword-level BERT; its own header redirects similarity tasks to `NLEmbedding`).
- **Created `Embedder.swift`** — wraps NLEmbedding with `vector(for:)`, `embed(_:)→Data?`, and `cosineSimilarity(query:stored:)→Double`. Uses `@preconcurrency import NaturalLanguage` for Swift 6.
- **Session embedding** on `stopSession(in:)`: concatenates all entry text and embeds synchronously (~50ms, imperceptible). Stored in existing `Session.embedding` (Data) field.
- **Standalone note embedding** on save in MenuBarContentView. Stored in `Entry.embedding`.
- **Semantic search in TimelineView**: replaced text-filter with cosine similarity ranking. Embed query → score all sessions/entries → sort by relevance. Text-match fallback for items without embeddings (old data, permission-denied sessions).
- **Package.swift**: added `NaturalLanguage` linker framework.
- **Swift 6 concurrency**: `ModelContext` is not `Sendable` — pivoted from `Task.detached` async to synchronous main-actor embedding. Documented in LEARNINGS.md.

### Learnings captured
- LEARNINGS.md: NLEmbedding API surface, `@preconcurrency` pattern, ModelContext Sendable limitation
- MEMORY.md: embedding API choice decision, architecture decisions

### Skill extracted
- **sdk-spike** (`/Users/david/workspace/sdk-spike-skill/SKILL.md`): verify → bench → wire pattern for new Apple framework adoption. Needs to be moved to `~/.claude/skills/` to be discoverable.

## Git State
- Branch: `main` at `1b700e3`
- Remote: `wretcher207/Afterthought` (GitHub)
- Pushed: yes
- Uncommitted: `_honcho_summary.txt` (temp), `Afterthought_handoff.md` (this file)

## In Progress / Not Yet Done
- **Session auto-summary** (LLM-based): when a session ends, generate a one-paragraph summary via on-device Foundation Models. This is the other half of 1c.
- **Live test on David's machine**: the 1c binary is at `.build/debug/Afterthought` but hasn't been run live with Screen Recording yet.

## Key Decisions Made
| Decision | Rationale |
|----------|-----------|
| `NLEmbedding` over `NLContextualEmbedding` | Header explicitly redirects similarity to NLEmbedding; NLContextualEmbedding is subword BERT |
| Synchronous embedding on main actor | ModelContext not Sendable — can't cross actors. 50ms is imperceptible. |
| Session-level embedding (concatenated text) over per-entry embedding | Fits episodic retrieval model: you search for sessions, not individual screenshots |
| `@preconcurrency import` over `nonisolated(unsafe)` | Standard Swift 6 migration pattern; NLEmbedding is read-only and thread-safe |

## Errors & Friction
- None that needed >2 attempts. Both `@preconcurrency` and `ModelContext` issues were one-shot fixes after reading compiler diagnostics.
- The `failed to store: 100001` warning on `git push` is a credential helper issue — push succeeds regardless.

## Next Session Priorities
1. **Session auto-summary**: at `stopSession(in:)`, call an on-device LLM (Apple's Foundation Models API on macOS 26) to generate a one-paragraph summary of the session's entries. Store in `Session.summary`. Embed the summary for retrieval.
2. **Live-test 1c**: build and run on David's machine with Screen Recording permission. Verify: start session → capture screenshots → stop → search semantically in timeline.
3. **Episodic query UI**: consider a dedicated query view ("What was I working on Tuesday morning?") that returns ranked session summaries instead of just a sorted timeline.
4. **Move sdk-spike skill** to `~/.claude/skills/` for discovery.

## Required Tools/Skills
- Xcode 26.5 with macOS 26.5 SDK
- `swift build --disable-sandbox` for CodeWhale-based verification
- Self-signed cert for stable TCC grants (see ERRORS.md)
- Honcho CLI (`honcho-connect.py`) for memory persistence
- `session-wrap` skill for end-of-session ritual
- `sdk-spike` skill for future Apple framework adoption
