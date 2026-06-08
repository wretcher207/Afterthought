import AppKit
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

            if appState.captureEngine.permission == .denied {
                permissionNotice
            }

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

    private var permissionNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Screen Recording is off", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("Afterthought needs Screen Recording permission to capture screenshots.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("Open System Settings", systemImage: "gearshape") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
    }

    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let entry = Entry(kind: .note, text: trimmed)
        modelContext.insert(entry)
        entry.session = appState.activeSession
        noteText = ""
    }

    private func startSession() {
        appState.startSession(in: modelContext)
    }

    private func stopSession() {
        appState.stopSession()
    }
}
