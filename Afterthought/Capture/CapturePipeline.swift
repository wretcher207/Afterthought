import CoreGraphics
import Foundation
import ScreenCaptureKit
import Vision

/// The result of capturing one display: a Sendable hand-off back to the main
/// actor for insertion into SwiftData. Deliberately carries no `CGImage` so
/// nothing non-Sendable crosses the actor boundary.
struct CapturedShot: Sendable {
    let relativeFilePath: String
    let text: String
}

/// The off-main capture work: grab every display, encode each to HEIC, OCR it.
///
/// All functions are `nonisolated` and `async` so the heavy ScreenCaptureKit /
/// ImageIO / Vision work runs off the main actor. Only the Sendable results
/// travel back to `CaptureEngine`.
enum CapturePipeline {
    /// Captures all displays once and returns a shot per display.
    ///
    /// The first call to `SCShareableContent.current` is what triggers (or
    /// fails against) the system Screen Recording permission, so the thrown
    /// error here is how the engine learns it's been denied.
    static func captureAllDisplays() async throws -> [CapturedShot] {
        let content = try await SCShareableContent.current
        guard !content.displays.isEmpty else { throw CaptureError.noDisplays }

        var shots: [CapturedShot] = []
        for display in content.displays {
            let filter = SCContentFilter(display: display, excludingWindows: [])

            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let relativePath = try MediaStore.writeScreenshot(image)
            let text = await recognizeText(in: image)
            shots.append(CapturedShot(relativeFilePath: relativePath, text: text))
        }
        return shots
    }

    /// Runs on-device OCR over a screenshot, returning newline-joined text.
    /// Failures degrade gracefully to an empty string — a screenshot with no
    /// recognizable text is still a valid memory.
    static func recognizeText(in image: CGImage) async -> String {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            let observations = try await request.perform(on: image)
            return observations
                .map(\.transcript)
                .joined(separator: "\n")
        } catch {
            return ""
        }
    }
}
