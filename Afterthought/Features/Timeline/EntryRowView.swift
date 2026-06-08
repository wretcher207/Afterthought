import SwiftUI

/// One entry in the timeline: an icon for its kind, its text, and a timestamp.
struct EntryRowView: View {
    let entry: Entry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: entry.kind.symbolName)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityLabel(entry.kind.label)

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
}
