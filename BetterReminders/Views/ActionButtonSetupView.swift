import SwiftUI

struct ActionButtonSetupView: View {
    var body: some View {
        List {
            Section {
                Text("Press the Action Button to start recording instantly — BetterReminders stays in the background. Your Dynamic Island shows audio levels, processing status, and which list your reminder was sorted into.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Setup Steps") {
                SetupStepRow(number: 1, title: "Open Settings", detail: "Go to Settings → Action Button on your iPhone.")
                SetupStepRow(number: 2, title: "Choose Shortcut", detail: "Select Shortcut as the Action Button action.")
                SetupStepRow(number: 3, title: "Pick Toggle Recording", detail: "Search for BetterReminders and select \"Toggle Recording\".")
                SetupStepRow(number: 4, title: "Grant Permissions First", detail: "Open BetterReminders once. Use in-app Record and allow Microphone, Speech Recognition, and Live Activities.")
            }

            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts App", systemImage: "arrow.up.forward.app")
                }
            }

            Section("How It Works") {
                Label("Press Action Button — recording starts, no app UI", systemImage: "1.circle.fill")
                Label("Speak your reminder — watch audio bars on Dynamic Island", systemImage: "2.circle.fill")
                Label("Press Action Button again or tap Stop on Live Activity", systemImage: "3.circle.fill")
                Label("Island shows transcribing → sorting → reminder + list", systemImage: "4.circle.fill")
            }

            Section("Stopping a Recording") {
                Text("iOS does not support hold-to-record for third-party apps. Use either:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("Press Action Button a second time", systemImage: "button.programmable")
                Label("Tap Stop on the Lock Screen or expanded Dynamic Island", systemImage: "stop.fill")
            }

            Section("Note") {
                Text("Live Activities must stay enabled. Processing runs in the background after you stop — the Dynamic Island will show progress until your reminder is saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("If recording fails") {
                Label("Enable Live Activities: Settings → BetterReminders → Live Activities", systemImage: "checkmark.circle")
                Label("Grant Microphone in BetterReminders first (in-app Record once)", systemImage: "checkmark.circle")
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
