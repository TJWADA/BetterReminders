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
                Label("Press Action Button to start recording", systemImage: "1.circle.fill")
                Label("Speak your reminder naturally", systemImage: "2.circle.fill")
                Label("Press Action Button again to stop", systemImage: "3.circle.fill")
                Label("Reminder is transcribed and sorted automatically", systemImage: "4.circle.fill")
            }

            Section("Note") {
                Text("A Live Activity will appear on your Dynamic Island while recording. iOS requires this to keep recording active in the background.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Action Button Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SetupStepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ActionButtonSetupView()
    }
}
