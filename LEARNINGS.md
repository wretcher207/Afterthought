# Afterthought — Learnings

Hard-won technical facts from development sessions. One crisp fact per bullet,
with enough context to reuse.

## 2026-06-08 — Sandbox nesting: Apple toolchain vs CodeWhale

- **Fact:** Apple's toolchain (xcodebuild, swiftpm, swiftc) wraps child processes in
  `sandbox-exec`, which calls `sandbox_apply()`. CodeWhale's outer sandbox denies that
  syscall, so nested sandboxing fails with "Operation not permitted".
- **Fix:** `swift build --disable-sandbox` tells SPM to skip its sandbox wrapper.
  Requires a `Package.swift` alongside the Xcode project. Both can coexist — XcodeGen
  owns the `.xcodeproj`, SPM uses `Package.swift`.
- **Use:** For CI/verification in CodeWhale, use `swift build --disable-sandbox`. For
  signing, bundling, and running, use `xcodebuild` on the host machine.

## 2026-06-08 — SwiftData relationship timing

- **Fact:** Setting a `@Model` relationship to an already context-managed object before
  the owning object is inserted into the context causes `EXC_BREAKPOINT` crash (SwiftData
  `_assertionFailure` in the setter).
- **Fix:** Always insert the new object FIRST (`context.insert(entry)`), then assign
  the relationship (`entry.session = session`). Both must be in the same context.
- **Catch:** Clean builds hide this — only surfaces at runtime during live capture.
  Test the capture path manually after any model change.

## 2026-06-08 — NLEmbedding sentence embedding API surface (macOS 26.5)

- **Fact:** `NLEmbedding.sentenceEmbedding(for: .english)` returns 512-dim `[Double]`
  vectors. The Swift-refined API differs from the ObjC header: `vector(for:)` returns
  `[Double]?` (not `[NSNumber]`), and the distance method is `distance(between:and:distanceType:)`
  (not `distanceBetweenString(_:andString:distanceType:)`).
- **Fact:** Empty strings return nil from `vector(for:)` — handle this gracefully.
- **Data storage:** `[Double]` round-trips losslessly through `Data` via
  `vec.withUnsafeBytes { Data($0) }` and `data.withUnsafeBytes { ptr in Array(ptr.bindMemory(to: Double.self)) }`.
- **Latency:** ~2.4 ms for a short sentence, ~68 ms for ~1200 chars, ~660 ms for ~12000 chars.
  Synchronous on the main actor is fine for typical session text (a few KB).
- **Use:** For semantic similarity (cosine search), use `NLEmbedding.sentenceEmbedding`.
  Do NOT use `NLContextualEmbedding` — it provides subword-level BERT embeddings (multiple
  vectors per token), and its own header redirects similarity tasks to NLEmbedding.

## 2026-06-08 — @preconcurrency for non-Sendable system frameworks

- **Fact:** Under Swift 6 strict concurrency, a `static let` of a non-`Sendable` type
  (like `NLEmbedding?`) triggers `#MutableGlobalVariable`. Xcode 26.5's NaturalLanguage
  framework headers don't annotate `NLEmbedding` as `Sendable`.
- **Fix:** `@preconcurrency import NaturalLanguage` downgrades the error to a warning
  and allows the code to compile. This is the standard Swift 6 migration pattern for
  Apple frameworks that haven't been fully audited yet.
- **Catch:** Only use `@preconcurrency` when you're confident the underlying type is
  thread-safe (NLEmbedding is read-only after creation, so it's fine).

## 2026-06-08 — SwiftData ModelContext is not Sendable

- **Fact:** `ModelContext` is not `Sendable` under Swift 6. You cannot capture it in a
  `Task.detached` closure — the compiler flags it as a data-race risk. Even if the
  detached task only uses it inside a `MainActor.run` block, the capture itself is rejected.
- **Fix:** Perform work synchronously on the main actor instead. For NLEmbedding (2-70ms),
  synchronous embedding on the main actor is imperceptible. For heavier work in the future,
  extract the data you need (text, IDs) on the main actor, compute off-main, then pass
  only the result back to the main actor — never the context itself.
- **Catch:** This is easy to miss during planning — you think "I'll do this async" but
  ModelContext won't let you. Always extract data first, compute off-main, re-fetch by ID.

## 2026-06-08 — TCC grant stability via self-signed cert

- **Fact:** Screen Recording (TCC) permission is keyed to the binary's cdhash under
  ad-hoc signing. Each rebuild changes the cdhash → grant is lost → re-prompt.
- **Fix:** A self-signed code-signing identity in the login keychain makes the
  designated requirement use `identifier + certificate leaf hash` instead of cdhash,
  which survives rebuilds.
- **Catch:** With a real signature (even self-signed), dyld enforces matching Team ID
  between the main binary and the debug dylib. Set `ENABLE_DEBUG_DYLIB: NO` in
  project.yml to use a single signed binary. Also: OpenSSL 3.x p12 export needs `-legacy`
  for macOS `security` to read it; empty p12 passwords fail with "MAC verification failed".
