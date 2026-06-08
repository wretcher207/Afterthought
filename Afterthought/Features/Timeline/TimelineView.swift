import SwiftData
import SwiftUI

/// The main window: browse and search captured memories.
///
/// Sessions group their entries; standalone quick-notes appear on their own.
/// Milestone 1c replaces the plain text filter with episodic semantic query.
struct TimelineView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \Session.startedAt, order: .reverse)
    private var sessions: [Session]

    @Query(sort: \Entry.createdAt, order: .reverse)
    private var allEntries: [Entry]

    @State private var searchText = ""

    /// Quick-notes and one-off captures that don't belong to a session.
    private var standaloneEntries: [Entry] {
        allEntries
            .filter { $0.session == nil }
            .filter { matches(searchText, in: $0.text) }
    }

    private var filteredSessions: [Session] {
        sessions.filter { session in
            searchText.isEmpty
                || matches(searchText, in: session.title)
                || session.entries.contains { matches(searchText, in: $0.text) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filteredSessions.isEmpty {
                    Section("Sessions") {
                        ForEach(filteredSessions) { session in
                            SessionRowView(session: session)
                        }
                    }
                }

                if !standaloneEntries.isEmpty {
                    Section("Quick Notes") {
                        ForEach(standaloneEntries) { entry in
                            EntryRowView(entry: entry)
                        }
                    }
                }

                if filteredSessions.isEmpty && standaloneEntries.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Memories Yet" : "No Matches",
                        systemImage: "brain.head.profile",
                        description: Text(
                            searchText.isEmpty
                                ? "Jot a quick note or start a session from the menu bar."
                                : "Nothing matches “\(searchText)”."
                        )
                    )
                }
            }
            .navigationTitle("Afterthought")
            .searchable(text: $searchText, prompt: "Search your memories")
        }
        .frame(minWidth: 480, minHeight: 360)
    }

    private func matches(_ query: String, in text: String) -> Bool {
        query.isEmpty || text.localizedCaseInsensitiveContains(query)
    }
}
