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

## 2026-06-08 — Screen Recording grant dropped on every rebuild (ad-hoc signing)

**What didn't work:** Ad-hoc (`Signature=adhoc`) signing — the default for an unsigned
local build. TCC keys the grant on the binary's cdhash, which changes every rebuild,
so the Screen Recording permission was lost each time and System Settings showed a
stale/non-matching entry ("toggled on but still denied").

**What worked instead:** A stable **self-signed code-signing identity** in the login
keychain + manual signing in `project.yml`. The designated requirement becomes
`identifier "com.deadpixel.afterthought" and certificate leaf = H"<hash>"` — no cdhash,
so the grant survives rebuilds. Grant once, done.

**Recreate the cert if it's ever missing** (new machine / deleted key → builds fail with
"signing identity not found", and a fresh cert = new hash = re-grant once):
```bash
CN="Afterthought Dev"; KC="$HOME/Library/Keychains/login.keychain-db"; PW="afterthought-dev"; W=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -keyout "$W/k.pem" -out "$W/c.pem" \
  -subj "/CN=$CN" -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" -addext "extendedKeyUsage=critical,codeSigning"
openssl pkcs12 -export -legacy -inkey "$W/k.pem" -in "$W/c.pem" -out "$W/id.p12" -passout pass:"$PW" -name "$CN"
security import "$W/id.p12" -k "$KC" -P "$PW" -A -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "" "$KC"; rm -rf "$W"
```
Gotchas that bit us: OpenSSL 3.x p12 needs `-legacy` for macOS `security` to read it;
an **empty p12 password fails** ("MAC verification failed") — use a real one; the cert
shows as `CSSMERR_TP_NOT_TRUSTED` / not in `find-identity -v`, but `codesign` signs with
it fine and TCC is happy (trust only matters for Gatekeeper launch, which dev launches
bypass).

**Follow-on crash:** after switching to the self-signed cert, the app crashed at launch
with `Library not loaded: @rpath/Afterthought.debug.dylib ... different Team IDs`. Xcode
splits debug builds into a separate `.debug.dylib`; with a real signature dyld enforces a
matching Team ID between it and the main binary, and our cert has none → rejected (ad-hoc
skips this check). Fix: `ENABLE_DEBUG_DYLIB: NO` in project.yml → single signed binary,
no mismatch. (Tradeoff: loses the debug-dylib build-speed/preview optimization; fine for
this project.)
