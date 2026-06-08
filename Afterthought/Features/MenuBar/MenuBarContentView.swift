import SwiftData
import SwiftUI

/// The menu-bar surface: jot a quick note, start/stop a capture session,
/// and open the main window. This is the fast path into Afterthought.
struct MenuBarContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(AppState.self) private var appState

    @State private var noteText = ""
    @FocusState private var noteFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            quickNoteField

            Divider()

            captureToggle

            Divider()

            Button("Open Afterthought", systemImage: "rectangle.stack") {
                openWindow(id: "main")
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { noteFieldFocused = true }
    }

    private var header: some View {
        HStack {
            Label("Afterthought", systemImage: "brain.head.profile")
                .font(.headline)
            Spacer()
            if appState.isCapturing {
                Label("Capturing", systemImage: "record.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    private var quickNoteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Quick note…", text: $noteText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($noteFieldFocused)
                .onSubmit(saveNote)

            Button("Save Note", systemImage: "square.and.arrow.down", action: saveNote)
                .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var captureToggle: some View {
        Group {
            if appState.isCapturing {
                Button("Stop Session", systemImage: "stop.circle", action: stopSession)
                    .tint(.red)
            } else {
                Button("Start Session", systemImage: "record.circle", action: startSession)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let entry = Entry(kind: .note, text: trimmed, session: appState.activeSession)
        modelContext.insert(entry)
        noteText = ""
    }

    private func startSession() {
        let session = Session(title: Self.defaultSessionTitle())
        modelContext.insert(session)
        appState.activeSession = session
    }

    private func stopSession() {
        appState.activeSession?.endedAt = .now
        appState.activeSession = nil
    }

    private static func defaultSessionTitle() -> String {
        let formatter = Date.FormatStyle(date: .abbreviated, time: .shortened)
        return "Session · \(Date.now.formatted(formatter))"
    }
}
