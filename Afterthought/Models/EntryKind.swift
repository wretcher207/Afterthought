import Foundation

/// The kind of capture an `Entry` represents.
///
/// Milestone 1 ships `.note` and `.screenshot`; `.audio` and `.video`
/// arrive in milestone 2 but are defined here so the model is stable.
enum EntryKind: String, Codable, CaseIterable, Sendable {
    case note
    case screenshot
    case audio
    case video

    var symbolName: String {
        switch self {
        case .note: "note.text"
        case .screenshot: "camera.viewfinder"
        case .audio: "waveform"
        case .video: "video"
        }
    }

    var label: String {
        switch self {
        case .note: "Note"
        case .screenshot: "Screenshot"
        case .audio: "Audio"
        case .video: "Video"
        }
    }
}
