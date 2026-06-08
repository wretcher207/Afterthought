import SwiftData
import SwiftUI

@main
struct AfterthoughtApp: App {
    @State private var appState = AppState()
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Session.self, Entry.self)
        } catch {
            fatalError("Failed to create the Afterthought data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            TimelineView()
                .environment(appState)
        }
        .modelContainer(container)

        MenuBarExtra("Afterthought", systemImage: "brain.head.profile") {
            MenuBarContentView()
                .environment(appState)
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
    }
}
