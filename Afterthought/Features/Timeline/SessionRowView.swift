import SwiftUI

/// A session in the timeline, expandable to reveal the entries captured in it.
struct SessionRowView: View {
    let session: Session

    private var sortedEntries: [Entry] {
        session.entries.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        DisclosureGroup {
            if sortedEntries.isEmpty {
                Text("No entries captured.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sortedEntries) { entry in
                    EntryRowView(entry: entry)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: session.isActive ? "record.circle" : "calendar")
                    .foregroundStyle(session.isActive ? .red : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                    Text("\(session.entries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
