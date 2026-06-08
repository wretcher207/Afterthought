# Afterthought — Error Log

Approaches that misfired and what fixed them. Check this before repeating a pattern.

## 2026-06-08 — SwiftData relationship set in initializer → hard crash

**What didn't work:** `Entry.init(kind:text:session:)` set `self.session = session`
inside the initializer, then the caller did `context.insert(entry)`. Live capture
crashed every tick with `EXC_BREAKPOINT` in `Entry.session.setter` →
`SwiftData ... _assertionFailure`. The quick-note path had the same latent bug —
it only survived because standalone notes passed `session: nil`.

**Why:** SwiftData asserts when you wire a relationship to an already context-managed
object (the `Session` was inserted in `startSession`) before the owning object (the
`Entry`) is itself inserted into a context. Setting the relationship on a free/
unregistered model is illegal.

**What worked instead:** Drop the relationship from the initializer. Insert the entry
first, THEN assign the relationship — both objects are now registered in the same
context:
```swift
let entry = Entry(kind: .screenshot, text: shot.text)
context.insert(entry)
entry.session = session   // safe: entry is now managed
```

**Note for next time:** For any `@Model`, set relationships AFTER `context.insert(...)`,
never in `init`. Caught only by running live — a clean build hides it.

## 2026-06-08 — Stale DerivedData binary launched by `open`

**What didn't work:** Two `Afterthought-*` DerivedData dirs existed; `find ... | head -1`
+ `open` launched a 2-hour-old build with no toolbar Start button, looking like the
feature was missing.

**What worked instead:** Pin the exact DerivedData path from the build log's
"Build description path", kill all instances, then `open` that specific `.app`.

**Note for next time:** After `xcodebuild`, launch the binary from the path printed in
the build output — don't trust `find | head`. Screen Recording (TCC) grants are also
tied to the exact binary, so each rebuild may re-prompt and require a relaunch.
