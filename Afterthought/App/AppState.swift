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
    let captureEngine = CaptureEngine()

    var isCapturing: Bool { activeSession != nil }

    /// Starts a new capture session and kicks off interval screenshots.
    func startSession(in context: ModelContext) {
        guard activeSession == nil else { return }
        let session = Session(title: Self.defaultSessionTitle())
        context.insert(session)
        activeSession = session
        captureEngine.start(session: session, in: context)
    }

    /// Ends the active session and stops capturing. Safe to call when idle.
    func stopSession() {
        captureEngine.stop()
        activeSession?.endedAt = .now
        activeSession = nil
    }

    private static func defaultSessionTitle() -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .shortened)
        return "Session · \(Date.now.formatted(formatter))"
    }
}
