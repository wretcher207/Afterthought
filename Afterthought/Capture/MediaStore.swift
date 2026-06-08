import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Where raw media lives on disk.
///
/// SwiftData holds only metadata + extracted text; the actual images sit as
/// files in the app's Application Support container (sandbox-safe, no extra
/// entitlement needed since it's the app's own container). `Entry.relativeFilePath`
/// stores just the filename, resolved back through `url(for:)`.
enum MediaStore {
    /// HEIC lossy quality. 0.6 keeps screenshots compact while staying well
    /// above the threshold where OCR'd text stays legible.
    static let heicQuality: CGFloat = 0.6

    /// `.../Application Support/Afterthought/Media`, created on first access.
    static var mediaDirectory: URL {
        get throws {
            let base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dir = base
                .appendingPathComponent("Afterthought", isDirectory: true)
                .appendingPathComponent("Media", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
    }

    /// Absolute URL for a stored entry's media, given its `relativeFilePath`.
    static func url(for relativePath: String) throws -> URL {
        try mediaDirectory.appendingPathComponent(relativePath)
    }

    /// Encodes a screenshot to HEIC on disk and returns the filename to store
    /// in `Entry.relativeFilePath`.
    static func writeScreenshot(_ image: CGImage) throws -> String {
        let filename = "\(UUID().uuidString).heic"
        let url = try mediaDirectory.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            throw CaptureError.encodingFailed
        }

        let options = [kCGImageDestinationLossyCompressionQuality: heicQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)

        guard CGImageDestinationFinalize(destination) else {
            throw CaptureError.encodingFailed
        }
        return filename
    }
}

/// Failures the capture pipeline can surface.
enum CaptureError: Error {
    case encodingFailed
    case noDisplays
}
