import Foundation
import SwiftData

/// A single captured memory: a quick note, a screenshot, or (later) audio/video.
///
/// An entry may belong to a `Session` (captured during a creative burst) or
/// stand alone (a one-off quick note). Raw media lives on disk; only the
/// metadata, extracted text, and embedding live in SwiftData.
@Model
final class Entry {
    var id: UUID = UUID()
    var createdAt: Date = Date.now

    /// Stored as the raw string so SwiftData predicates can filter on it.
    var kindRaw: String = EntryKind.note.rawValue

    /// Note body, or text extracted from a screenshot/transcript via OCR.
    var text: String = ""

    /// On-device summary, populated by the intelligence layer (milestone 1c).
    var summary: String?

    /// Path to the raw media file, relative to the app's media directory.
    var relativeFilePath: String?

    /// Sentence embedding for episodic retrieval, stored as raw `[Float]` bytes.
    var embedding: Data?

    /// The session this entry was captured during, if any.
    var session: Session?

    init(kind: EntryKind, text: String = "", session: Session? = nil) {
        self.kindRaw = kind.rawValue
        self.text = text
        self.session = session
    }

    var kind: EntryKind {
        get { EntryKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }
}
