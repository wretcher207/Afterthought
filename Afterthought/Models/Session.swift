import Foundation
import SwiftData

/// A time-bounded creative burst that groups the entries captured during it.
///
/// Sessions are the primary unit of episodic memory: when a session ends, the
/// intelligence layer summarizes and embeds it (milestone 1c) so the whole
/// episode can be retrieved by meaning and time.
@Model
final class Session {
    var id: UUID = UUID()
    var title: String = ""
    var startedAt: Date = Date.now
    var endedAt: Date?

    /// On-device episodic summary of everything captured in this session.
    var summary: String?

    /// Embedding of `summary`, stored as raw `[Float]` bytes for cosine search.
    var embedding: Data?

    @Relationship(deleteRule: .cascade, inverse: \Entry.session)
    var entries: [Entry] = []

    init(title: String) {
        self.title = title
    }

    var isActive: Bool { endedAt == nil }
}
