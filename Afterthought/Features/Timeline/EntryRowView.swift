import AppKit
import SwiftUI

/// One entry in the timeline: an icon (or thumbnail for screenshots),
/// its text, and a timestamp.
struct EntryRowView: View {
    let entry: Entry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            thumbnailOrIcon
                .frame(width: 44, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text.isEmpty ? entry.kind.label : entry.text)
                    .lineLimit(3)
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var thumbnailOrIcon: some View {
        if entry.kind == .screenshot, let path = entry.relativeFilePath {
            ScreenshotThumbnail(relativePath: path)
        } else {
            Image(systemName: entry.kind.symbolName)
                .foregroundStyle(.secondary)
                .accessibilityLabel(entry.kind.label)
        }
    }
}

/// Loads a HEIC screenshot from the app's media container and displays it.
private struct ScreenshotThumbnail: View {
    let relativePath: String
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .task {
            image = loadImage()
        }
    }

    private func loadImage() -> NSImage? {
        guard let url = try? MediaStore.url(for: relativePath) else { return nil }
        return NSImage(contentsOf: url)
    }
}
