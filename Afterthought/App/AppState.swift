import Foundation
import Observation
import SwiftData

/// App-wide UI state shared between the menu-bar surface and the main window.
@MainActor
@Observable
final class AppState {
    /// The session currently capturing, if any. `nil` means idle.
    var activeSession: Session?

    /// Drives interval screen capture for the active session.
    let captureEngine: CaptureEngine

    var isCapturing: Bool { activeSession != nil }

    init() {
        captureEngine = CaptureEngine()
        captureEngine.onPermissionDenied = { [weak self] in
            self?.stopSession()
        }
    }

    /// Starts a new capture session and kicks off interval screenshots.
    func startSession(in context: ModelContext) {
        guard activeSession == nil else { return }
        let session = Session(title: Self.defaultSessionTitle())
        context.insert(session)
        activeSession = session
        captureEngine.start(session: session, in: context)
    }

    /// Ends the active session, stops capturing, and generates an embedding
    /// for semantic search. Safe to call when idle.
    ///
    /// When `context` is provided, the session's entry text is embedded
    /// and stored for semantic search. When nil (e.g. called from the
    /// permission-denied callback), only the session lifecycle is updated.
    func stopSession(in context: ModelContext? = nil) {
        captureEngine.stop()
        activeSession?.endedAt = .now
        let session = activeSession
        activeSession = nil

        guard let session, let context else { return }

        // Embed the session's text. NLEmbedding.vector(for:) takes ~2-70 ms
        // for typical session text — fast enough to run synchronously.
        let text = session.entries
            .map(\.text)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        if !text.isEmpty {
            session.embedding = Embedder.embed(text)
            try? context.save()
        }
    }

    private static func defaultSessionTitle() -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .shortened)
        return "Session · \(Date.now.formatted(formatter))"
    }
}
