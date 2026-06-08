import Foundation
import Observation
import SwiftData

/// Drives interval screen capture for an active session.
///
/// Kept deliberately modular (it knows nothing about the menu bar or windows)
/// so the distribution decision never forces a rewrite. It owns the capture
/// loop and the Screen Recording permission state; the actual grabbing/OCR/
/// encoding happens off-main in `CapturePipeline`, and only Sendable results
/// come back here to be inserted into SwiftData on the main actor.
@MainActor
@Observable
final class CaptureEngine {
    /// Seconds between screenshots while a session is capturing.
    static let captureInterval: TimeInterval = 60

    enum Permission {
        case unknown
        case authorized
        case denied
    }

    private(set) var permission: Permission = .unknown

    /// Called when Screen Recording permission is denied (so AppState can
    /// end the active session before it becomes an orphan).
    var onPermissionDenied: (@MainActor () -> Void)?

    private var loopTask: Task<Void, Never>?

    var isRunning: Bool { loopTask != nil }

    /// Begins capturing into `session`, taking one shot immediately and then
    /// every `captureInterval` seconds until `stop()` is called.
    func start(session: Session, in context: ModelContext) {
        guard loopTask == nil else { return }
        let sessionID = session.persistentModelID

        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.captureCycle(sessionID: sessionID, in: context)
                guard !Task.isCancelled else { break }
                try? await Task.sleep(for: .seconds(Self.captureInterval))
            }
        }
    }

    /// Stops the capture loop. Safe to call when idle.
    func stop() {
        loopTask?.cancel()
        loopTask = nil
    }

    /// One capture tick: grab all displays off-main, then insert an `Entry`
    /// per shot, re-fetching the session by ID so we never hold a stale model.
    private func captureCycle(sessionID: PersistentIdentifier, in context: ModelContext) async {
        do {
            let shots = try await CapturePipeline.captureAllDisplays()
            permission = .authorized

            guard let session = context.model(for: sessionID) as? Session else { return }
            for shot in shots {
                let entry = Entry(kind: .screenshot, text: shot.text)
                entry.relativeFilePath = shot.relativeFilePath
                context.insert(entry)
                entry.session = session
            }
        } catch {
            // The first failure is almost always Screen Recording being denied;
            // surface it and stop hammering the system with prompts.
            permission = .denied
            onPermissionDenied?()
            stop()
        }
    }
}
