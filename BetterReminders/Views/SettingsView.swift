import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var apiKey = KeychainHelper.loadAPIKey() ?? ""
    @State private var showSavedConfirmation = false
    @State private var saveError: String?
    @State private var testResult: String?
    @State private var isTestingKey = false
    @State private var showingOnboarding = false

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
                    Button(isTestingKey ? "Testing…" : "Test API Key") {
                        Task { await testAPIKey() }
                    }
                    .disabled(isTestingKey || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.contains("valid") ? .green : .red)
                    }
                    Text("Get your key from platform.openai.com/api-keys. This is not your ChatGPT login — you need a separate API key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Open OpenAI API Keys", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(.caption)
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
                    Button("Show Setup Guide") {
                        showingOnboarding = true
                    }
                }
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView()
            }
        }
    }

    private func saveAPIKey() {
        saveError = nil
        testResult = nil
        showSavedConfirmation = false
        let trimmed = KeychainHelper.sanitizeAPIKey(apiKey)
        guard !trimmed.isEmpty else {
            saveError = "API key cannot be empty"
            return
        }
        do {
            try KeychainHelper.saveAPIKey(trimmed)
            apiKey = trimmed
            showSavedConfirmation = true
            HapticHelper.notification(.success)
        } catch {
            saveError = error.localizedDescription
            HapticHelper.notification(.error)
        }
    }

    private func testAPIKey() async {
        isTestingKey = true
        testResult = nil
        saveError = nil

        let trimmed = KeychainHelper.sanitizeAPIKey(apiKey)
        guard KeychainHelper.isValidOpenAIKeyFormat(trimmed) else {
            testResult = "Invalid key format. Keys should start with sk-."
            isTestingKey = false
            return
        }

        do {
            try KeychainHelper.saveAPIKey(trimmed)
            apiKey = trimmed
            try await ReminderParserService.validateAPIKey()
            testResult = "API key is valid."
            showSavedConfirmation = true
            HapticHelper.notification(.success)
        } catch {
            testResult = error.localizedDescription
            HapticHelper.notification(.error)
        }

        isTestingKey = false
    }
}

#Preview {
    SettingsView()
}
