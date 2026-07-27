import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var step = 0
    @State private var apiKey = KeychainHelper.loadAPIKey() ?? ""
    @State private var micGranted = AudioRecordingService.shared.hasMicrophonePermission
    @State private var speechGranted = false
    @State private var notificationsGranted = false
    @State private var saveError: String?

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $step) {
                    welcomePage.tag(0)
                    permissionsPage.tag(1)
                    apiKeyPage.tag(2)
                    actionButtonPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: step)

                bottomBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            withAnimation { step -= 1 }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        finishOnboarding()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .task {
                await refreshPermissionStatus()
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor)
            Text("Welcome to BetterReminders")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Speak naturally and let AI turn your voice memos into organized reminders.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
    }

    private var permissionsPage: some View {
        List {
            Section {
                Text("BetterReminders needs a few permissions to capture and process voice reminders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Required Permissions") {
                permissionRow(
                    title: "Microphone",
                    detail: "Record voice reminders",
                    isGranted: micGranted
                ) {
                    await AudioRecordingService.shared.requestMicrophonePermission()
                }

                permissionRow(
                    title: "Speech Recognition",
                    detail: "Transcribe on device",
                    isGranted: speechGranted
                ) {
                    let status = await SpeechService.requestAuthorization()
                    return status == .authorized
                }

                permissionRow(
                    title: "Notifications",
                    detail: "Due-date alerts and confirmations",
                    isGranted: notificationsGranted
                ) {
                    let granted = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    return granted ?? false
                }
            }
        }
    }

    private var apiKeyPage: some View {
        Form {
            Section {
                Text("BetterReminders uses OpenAI to parse your spoken reminders into titles, due dates, and lists.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("OpenAI API Key") {
                SecureField("sk-…", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if let saveError {
                    Text(saveError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Link("Get an API key at platform.openai.com", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
        }
    }

    private var actionButtonPage: some View {
        List {
            Section {
                Text("On iPhone 15 Pro and later, bind the Action Button for instant hands-free capture.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Quick Setup") {
                SetupStepRow(number: 1, title: "Open Settings", detail: "Go to Settings → Action Button.")
                SetupStepRow(number: 2, title: "Choose Shortcut", detail: "Select Shortcut as the action.")
                SetupStepRow(number: 3, title: "Toggle Recording", detail: "Pick BetterReminders → Toggle Recording.")
            }

            Section {
                NavigationLink {
                    ActionButtonSetupView()
                } label: {
                    Label("Full Setup Guide", systemImage: "button.programmable")
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if step == totalSteps - 1 {
                Button("Get Started") {
                    saveAPIKeyIfNeeded()
                    finishOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("Continue") {
                    if step == 2 {
                        saveAPIKeyIfNeeded()
                    }
                    withAnimation { step += 1 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.bar)
    }

    private func permissionRow(
        title: String,
        detail: String,
        isGranted: Bool,
        request: @escaping () async -> Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Allow") {
                    Task {
                        _ = await request()
                        await refreshPermissionStatus()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private func refreshPermissionStatus() async {
        micGranted = AudioRecordingService.shared.hasMicrophonePermission
        speechGranted = SpeechService.authorizationStatus == .authorized
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsGranted = settings.authorizationStatus == .authorized
    }

    private func saveAPIKeyIfNeeded() {
        saveError = nil
        let trimmed = KeychainHelper.sanitizeAPIKey(apiKey)
        guard !trimmed.isEmpty else { return }
        do {
            try KeychainHelper.saveAPIKey(trimmed)
            apiKey = trimmed
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func finishOnboarding() {
        saveAPIKeyIfNeeded()
        settings.hasCompletedOnboarding = true
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
