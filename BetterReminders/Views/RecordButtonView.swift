import SwiftUI
import SwiftData
import BetterRemindersCore

struct RecordButtonView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProcessingJob.createdAt, order: .reverse) private var jobs: [ProcessingJob]

    @State private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared
    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var permissionDenied = false
    @State private var showSuccess = false
    @State private var recordingError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    recordButtonSection
                    statusSection
                    if !jobs.isEmpty {
                        recentJobsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Record")
            .alert("Microphone Access Required", isPresented: $permissionDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable microphone and speech recognition in Settings to record reminders.")
            }
        }
    }

    private var recordButtonSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(recorder.isRecording ? Color.red.opacity(0.15) : Color.accentColor.opacity(0.12))
                    .frame(width: 200, height: 200)
                    .scaleEffect(recorder.isRecording ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recorder.isRecording)

                Button {
                    Task { await toggleRecording() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color.accentColor)
                            .frame(width: 120, height: 120)
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(processor.isProcessing)
            }
            .padding(.top, 8)

            if recorder.isRecording {
                Text(formattedElapsed(Int(recorder.elapsedTime)))
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .id(displayTick)
                Text("Tap to stop recording")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap to record a reminder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statusSection: some View {
        if processor.isProcessing {
            ProcessingOverlayView(status: processor.currentStatus, error: processor.lastError)
        } else if let recordingError {
            ProcessingOverlayView(status: nil, error: recordingError)
        } else if showSuccess, !processor.lastCreatedTitles.isEmpty {
            VStack(spacing: 8) {
                Label("Reminders created", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                ForEach(processor.lastCreatedTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var recentJobsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Processing")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(jobs.prefix(5)) { job in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.transcript ?? "Voice memo")
                                .font(.caption)
                                .lineLimit(2)
                            Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        statusBadge(for: job.status)
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
                    if job.status == .failed, let errorMessage = job.errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for status: JobStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor(status))
    }

    private func statusColor(_ status: JobStatus) -> Color {
        switch status {
        case .done: return .green
        case .failed: return .red
        case .pending, .transcribing, .parsing: return .orange
        }
    }

    private func toggleRecording() async {
        showSuccess = false
        recordingError = nil

        if KeychainHelper.loadAPIKey()?.isEmpty ?? true {
            recordingError = "OpenAI API key not configured. Add it in Settings first."
            HapticHelper.notification(.error)
            return
        }

        if !recorder.hasMicrophonePermission {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                permissionDenied = true
                return
            }
        }

        let speechStatus = await SpeechService.requestAuthorization()
        guard speechStatus == .authorized else {
            permissionDenied = true
            return
        }

        do {
            if recorder.isRecording {
                HapticHelper.recordingStopped()
                guard let url = recorder.stopRecording() else { return }
                await RecordingCoordinator.shared.stopMeterTimer()
                stopDisplayTimer()
                await RecordingLiveActivityManager.showTranscribing()
                await processRecording(at: url)
            } else {
                HapticHelper.recordingStarted()
                try await RecordingLiveActivityManager.start()
                _ = try recorder.startRecording()
                startDisplayTimer()
                await RecordingCoordinator.shared.startMeterTimer()
            }
        } catch {
            recordingError = error.localizedDescription
            HapticHelper.notification(.error)
        }
    }

    private func processRecording(at url: URL) async {
        await processor.processRecording(
            audioURL: url,
            modelContext: modelContext,
            retainAudio: AppSettings.shared.retainAudio,
            updatesLiveActivity: true
        )
        if processor.currentStatus == .done {
            HapticHelper.notification(.success)
            showSuccess = true
        } else if processor.currentStatus == .failed {
            HapticHelper.notification(.error)
        }
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            displayTick += 1
        }
    }

    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
}

#Preview {
    RecordButtonView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
