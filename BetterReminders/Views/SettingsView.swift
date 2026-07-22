import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var apiKey = KeychainHelper.loadAPIKey() ?? ""
    @State private var showSavedConfirmation = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI API Key") {
                    SecureField("sk-…", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    if showSavedConfirmation {
                        Label("API key saved securely", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    if let saveError {
                        Text(saveError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Text("Your key is stored in the Keychain and used to categorize reminders via OpenAI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Recording") {
                    Toggle("Keep Original Audio", isOn: $settings.retainAudio)
                    Text("When enabled, voice memos are saved with each reminder.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Action Button") {
                    NavigationLink {
                        ActionButtonSetupView()
                    } label: {
                        Label("Set Up Action Button", systemImage: "button.programmable")
                    }
                }

                Section("Permissions") {
                    Button("Request Microphone Permission") {
                        Task {
                            _ = await AudioRecordingService.shared.requestMicrophonePermission()
                        }
                    }
                    Button("Request Speech Recognition") {
                        Task {
                            _ = await SpeechService.requestAuthorization()
                        }
                    }
                    Button("Request Notifications") {
                        Task {
                            _ = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .sound])
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Requires", value: "iOS 18+")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func saveAPIKey() {
        saveError = nil
        showSavedConfirmation = false
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            saveError = "API key cannot be empty"
            return
        }
        do {
            try KeychainHelper.saveAPIKey(trimmed)
            showSavedConfirmation = true
            HapticHelper.notification(.success)
        } catch {
            saveError = error.localizedDescription
            HapticHelper.notification(.error)
        }
    }
}

#Preview {
    SettingsView()
}
