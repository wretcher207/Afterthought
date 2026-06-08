import AppKit
import SwiftData
import SwiftUI

/// The main window: browse and search captured memories.
///
/// Sessions group their entries; standalone quick-notes appear on their own.
/// Milestone 1c replaces the plain text filter with episodic semantic query.
struct TimelineView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Session.startedAt, order: .reverse)
    private var sessions: [Session]

    @Query(sort: \Entry.createdAt, order: .reverse)
    private var allEntries: [Entry]

    @State private var searchText = ""

    /// Sessions ranked by semantic similarity to the search query.
    /// Falls back to text matching when embeddings aren't available.
    private var rankedSessions: [(session: Session, score: Double)] {
        guard !searchText.isEmpty, let queryVec = Embedder.vector(for: searchText) else {
            return sessions.map { ($0, 0) }
        }

        return sessions.map { session in
            if let emb = session.embedding {
                (session, Embedder.cosineSimilarity(query: queryVec, stored: emb))
            } else if matches(searchText, in: session.title)
                        || session.entries.contains(where: { matches(searchText, in: $0.text) }) {
                (session, 0.15)
            } else {
                (session, -1)
            }
        }
        .filter { $0.score >= 0 }
        .sorted { $0.score > $1.score }
    }

    /// Standalone entries ranked by semantic similarity.
    private var rankedStandalone: [(entry: Entry, score: Double)] {
        let standalones = allEntries.filter { $0.session == nil }

        guard !searchText.isEmpty, let queryVec = Embedder.vector(for: searchText) else {
            return standalones.map { ($0, 0) }
        }

        return standalones.map { entry in
            if let emb = entry.embedding {
                (entry, Embedder.cosineSimilarity(query: queryVec, stored: emb))
            } else if matches(searchText, in: entry.text) {
                (entry, 0.15)
            } else {
                (entry, -1)
            }
        }
        .filter { $0.score >= 0 }
        .sorted { $0.score > $1.score }
    }

    var body: some View {
        NavigationStack {
            List {
                if !rankedSessions.isEmpty {
                    Section("Sessions") {
                        ForEach(rankedSessions, id: \.session.id) { item in
                            SessionRowView(session: item.session)
                        }
                    }
                }

                if !rankedStandalone.isEmpty {
                    Section("Quick Notes") {
                        ForEach(rankedStandalone, id: \.entry.id) { item in
                            EntryRowView(entry: item.entry)
                        }
                    }
                }

                if rankedSessions.isEmpty && rankedStandalone.isEmpty {
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
            .safeAreaInset(edge: .top) {
                if appState.captureEngine.permission == .denied {
                    permissionBanner
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if appState.isCapturing {
                        Button("Stop Session", systemImage: "stop.circle") {
                            appState.stopSession(in: modelContext)
                        }
                        .tint(.red)
                    } else {
                        Button("Start Session", systemImage: "record.circle") {
                            appState.startSession(in: modelContext)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 480, minHeight: 360)
    }

    private var permissionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Screen Recording is off — screenshots can't be captured.")
                .font(.callout)
            Spacer()
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func matches(_ query: String, in text: String) -> Bool {
        query.isEmpty || text.localizedCaseInsensitiveContains(query)
    }
}
