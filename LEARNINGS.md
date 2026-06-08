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
