import SwiftUI

struct ActionButtonSetupView: View {
    var body: some View {
        List {
            Section {
                Text("BetterReminders works with the iPhone Action Button on iPhone 15 Pro and later. Set it up once to capture voice reminders instantly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Setup Steps") {
                SetupStepRow(number: 1, title: "Open Settings", detail: "Go to Settings → Action Button on your iPhone.")
                SetupStepRow(number: 2, title: "Choose Shortcut", detail: "Select Shortcut as the Action Button action.")
                SetupStepRow(number: 3, title: "Pick Toggle Recording", detail: "Search for BetterReminders and select \"Toggle Recording\".")
                SetupStepRow(number: 4, title: "Grant Permissions", detail: "Open BetterReminders once and allow Microphone and Speech Recognition.")
            }

            Section {
                Link(destination: URL(string: "shortcuts://")!) {
                    Label("Open Shortcuts App", systemImage: "arrow.up.forward.app")
                }
            }

            Section("How It Works") {
                Label("Press Action Button — BetterReminders opens and recording starts", systemImage: "1.circle.fill")
                Label("Speak your reminder naturally", systemImage: "2.circle.fill")
                Label("You can leave the app; recording continues on Dynamic Island", systemImage: "3.circle.fill")
                Label("Press Action Button again to stop and process", systemImage: "4.circle.fill")
            }

            Section("Note") {
                Text("iOS requires BetterReminders to open briefly when starting a recording so the Live Activity can activate. After that, you can switch apps or lock your phone while recording continues.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("If you see \"Toggle activation failed\"") {
                Label("Enable Live Activities: Settings → BetterReminders → Live Activities", systemImage: "checkmark.circle")
                Label("Grant Microphone access in BetterReminders first (use in-app Record once)", systemImage: "checkmark.circle")
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
