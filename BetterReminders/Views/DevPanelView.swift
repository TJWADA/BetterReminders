import SwiftUI
import SwiftData
import UserNotifications
import BetterRemindersCore

struct DevPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ProcessingJob.createdAt, order: .reverse) private var jobs: [ProcessingJob]
    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]

    @Bindable private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared
    @State private var micGranted = false
    @State private var speechGranted = false
    @State private var notificationsGranted = false
    @State private var apiKeyConfigured = false
    @State private var isRunningSpokenSort = false
    @State private var showingSpokenSortConfirm = false
    @State private var selectedSpokenSortPresetID = SpokenSortCatalog.fitnessSplit.id
    @State private var lastSpokenSortPresetName: String?
    @State private var spokenSortProgress: String?
    @State private var spokenSortResults: [SpokenSortResult] = []

    private var selectedSpokenSortPreset: SpokenSortPreset {
        SpokenSortCatalog.preset(id: selectedSpokenSortPresetID)
    }

    private var spokenSortPassedCount: Int {
        spokenSortResults.filter(\.passed).count
    }

    private var canRunSpokenSort: Bool {
        apiKeyConfigured && !isRunningSpokenSort && !processor.isProcessing
    }

    private var hasRecentActivity: Bool {
        processor.isProcessing
            || processor.lastError != nil
            || !processor.lastCreatedTitles.isEmpty
            || !jobs.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                spokenSortTestSection
                classificationFeedbackSection
                if hasRecentActivity {
                    jobsSection
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(isRunningSpokenSort)
                }
            }
            .interactiveDismissDisabled(isRunningSpokenSort)
            .confirmationDialog(
                "Run \(selectedSpokenSortPreset.name)?",
                isPresented: $showingSpokenSortConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset lists and run", role: .destructive) {
                    Task { await runSpokenSortScript() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces all lists with \(selectedSpokenSortPreset.name) and deletes existing reminders.")
            }
            .onAppear {
                refreshStatus()
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            statusRow("Recording", value: recorder.isRecording ? "Active" : "Idle",
                      isGood: !recorder.isRecording)
            if recorder.isRecording {
                statusRow("Elapsed", value: DurationFormatter.mmss(from: recorder.elapsedTime), isGood: true)
            }
            statusRow("Processing", value: processor.isProcessing ? "In progress" : "Idle",
                      isGood: !processor.isProcessing)
            statusRow("API Key", value: apiKeyConfigured ? "Configured" : "Missing", isGood: apiKeyConfigured)
            statusRow("Microphone", value: micGranted ? "Granted" : "Denied", isGood: micGranted)
            statusRow("Speech", value: speechGranted ? "Granted" : "Denied", isGood: speechGranted)
            statusRow("Notifications", value: notificationsGranted ? "Granted" : "Denied", isGood: notificationsGranted)
        }
    }

    private var spokenSortTestSection: some View {
        Section("Spoken Sort Test") {
            Picker("Persona", selection: $selectedSpokenSortPresetID) {
                ForEach(SpokenSortCatalog.all) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }
            .disabled(isRunningSpokenSort)

            Text(selectedSpokenSortPreset.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Run spoken sort script") {
                showingSpokenSortConfirm = true
            }
            .disabled(!canRunSpokenSort)

            if !apiKeyConfigured {
                Text("Add an OpenAI API key in Settings to run this script.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let spokenSortProgress {
                Text(spokenSortProgress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !spokenSortResults.isEmpty {
                Text(spokenSortResultsHeader)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(spokenSortPassedCount == spokenSortResults.count ? Color.green : Color.orange)

                ForEach(spokenSortResults) { result in
                    spokenSortResultRow(result)
                }
            }
        }
    }

    private var spokenSortResultsHeader: String {
        let name = lastSpokenSortPresetName ?? selectedSpokenSortPreset.name
        return "\(name): \(spokenSortPassedCount) of \(spokenSortResults.count) passed"
    }

    private func spokenSortResultRow(_ result: SpokenSortResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.say)
                    .font(.caption)
                Spacer()
                Text(result.passed ? "Pass" : "Fail")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(result.passed ? Color.green : failColor(for: result))
            }
            Text("Expected: \(result.expectedLists.joined(separator: ", "))")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if result.actualLists.isEmpty {
                Text(result.errorMessage ?? "Actual: none")
                    .font(.caption2)
                    .foregroundStyle(.red)
            } else {
                Text("Actual: \(zippedPlacements(result))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .textSelection(.enabled)
    }

    private func failColor(for result: SpokenSortResult) -> Color {
        switch result.kind {
        case .borderline, .split:
            return .orange
        case .clear, .catchAll:
            return .red
        }
    }

    private func zippedPlacements(_ result: SpokenSortResult) -> String {
        zip(result.actualTitles, result.actualLists)
            .map { "\($0) → \($1)" }
            .joined(separator: "; ")
    }

    private func runSpokenSortScript() async {
        let preset = selectedSpokenSortPreset
        isRunningSpokenSort = true
        spokenSortResults = []
        lastSpokenSortPresetName = preset.name
        spokenSortProgress = "\(preset.name): preparing lists…"
        refreshStatus()

        let results = await SpokenSortTestScript.run(
            preset: preset,
            modelContext: modelContext,
            processor: processor
        ) { current, total, phrase in
            spokenSortProgress = "\(preset.name) \(current) / \(total): \(phrase)"
        }

        spokenSortResults = results
        spokenSortProgress = nil
        isRunningSpokenSort = false
    }

    private var classificationFeedbackSection: some View {
        Section("Classification Feedback") {
            if lists.isEmpty {
                Text("No lists")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lists) { list in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(list.name)
                            .font(.subheadline.weight(.semibold))
                        if list.misclassificationLog.isEmpty {
                            Text("None")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(list.misclassificationLog, id: \.self) { note in
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var jobsSection: some View {
        Section("Recent Jobs") {
            if processor.isProcessing, let status = processor.currentStatus {
                Label(status.rawValue.capitalized, systemImage: "arrow.triangle.2.circlepath")
            }
            if !processor.lastCreatedTitles.isEmpty {
                ForEach(processor.lastCreatedTitles, id: \.self) { title in
                    Label(title, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            if let error = processor.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            ForEach(jobs.prefix(10)) { job in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(job.transcript ?? "Voice memo")
                            .font(.caption)
                            .lineLimit(2)
                        Spacer()
                        Text(job.status.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(statusColor(job.status))
                    }
                    Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if job.status == .failed, let errorMessage = job.errorMessage {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                    if job.status == .failed {
                        Button("Retry") {
                            Task {
                                await processor.retryJob(
                                    job,
                                    modelContext: modelContext,
                                    retainAudio: AppSettings.shared.retainAudio
                                )
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func statusRow(_ label: String, value: String, isGood: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(isGood ? Color.secondary : Color.red)
        }
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .done: return .green
        case .failed: return .red
        case .pending, .transcribing, .parsing: return .orange
        }
    }

    private func refreshStatus() {
        micGranted = recorder.hasMicrophonePermission
        speechGranted = SpeechService.authorizationStatus == .authorized
        apiKeyConfigured = !(KeychainHelper.loadAPIKey()?.isEmpty ?? true)
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsGranted = settings.authorizationStatus == .authorized
        }
    }
}
