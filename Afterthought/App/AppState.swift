import Foundation
import Observation

/// App-wide UI state shared between the menu-bar surface and the main window.
@MainActor
@Observable
final class AppState {
    /// The session currently capturing, if any. `nil` means idle.
    var activeSession: Session?

    /// Drives interval screen capture for the active session.
    let captureEngine = CaptureEngine()

    var isCapturing: Bool { activeSession != nil }
}
