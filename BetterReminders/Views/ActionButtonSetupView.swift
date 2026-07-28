import SwiftUI

struct ActionButtonSetupView: View {
    var body: some View {
        List {
            Section {
                Text("Use the Action Button to open BetterReminders and record hands-free — no screen taps needed. Everything happens on the in-app Record screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Setup Steps") {
                SetupStepRow(number: 1, title: "Open Settings", detail: "Go to Settings → Action Button on your iPhone.")
                SetupStepRow(number: 2, title: "Choose Shortcut", detail: "Select Shortcut as the Action Button action.")
                SetupStepRow(number: 3, title: "Pick Toggle Recording", detail: "Search for BetterReminders and select \"Toggle Recording\".")
                SetupStepRow(number: 4, title: "Grant Permissions First", detail: "Open BetterReminders once. Use in-app Record and allow Microphone and Speech Recognition. Add your OpenAI API key in Settings.")
            }

            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts App", systemImage: "arrow.up.forward.app")
                }
            }

            Section("How It Works") {
                Label("Press 1 — app opens to the Record tab", systemImage: "1.circle.fill")
                Label("Press 2 — recording starts (watch the in-app UI)", systemImage: "2.circle.fill")
                Label("Press 3 — recording stops and your reminder is saved", systemImage: "3.circle.fill")
            }

            Section("Stopping a Recording") {
                Text("iOS does not support hold-to-record for third-party apps. To stop, either:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Press the Action Button a third time", systemImage: "button.programmable")
                Label("Tap the red stop button on screen", systemImage: "stop.fill")
            }

            Section("If recording fails") {
                Label("Add your OpenAI API key in Settings", systemImage: "checkmark.circle")
                Label("Grant Microphone and Speech Recognition (in-app Record once)", systemImage: "checkmark.circle")
                Label("Re-select Toggle Recording in Settings → Action Button", systemImage: "checkmark.circle")
            }
        }
        .navigationTitle("Action Button Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ActionButtonSetupView()
    }
}
