import SwiftUI
import SwiftData
import BetterRemindersCore

@MainActor
enum RecordingFlowController {
    static func toggleRecording(
        recorder: AudioRecordingService,
        processor: ReminderProcessingService,
        modelContext: ModelContext,
        retainAudio: Bool,
        defaultList: ReminderList? = nil,
        onRecordingError: (String) -> Void,
        onPermissionDenied: () -> Void,
        startDisplayTimer: () -> Void,
        stopDisplayTimer: () -> Void
    ) async {
        do {
            try APIKeyValidator.requireConfigured()
            try await RecordingPermissions.ensureAuthorized(recorder: recorder)

            if recorder.isRecording {
                HapticHelper.recordingStopped()
                guard let url = recorder.stopRecording() else { return }
                stopDisplayTimer()
                await processStoppedRecording(
                    at: url,
                    processor: processor,
                    modelContext: modelContext,
                    retainAudio: retainAudio,
                    defaultList: defaultList
                )
            } else {
                HapticHelper.recordingStarted()
                _ = try recorder.startRecording()
                startDisplayTimer()
            }
        } catch let error as APIKeyValidator.ValidationError {
            onRecordingError(error.localizedDescription ?? APIKeyValidator.missingKeyMessage)
            HapticHelper.notification(.error)
        } catch is RecordingPermissions.ValidationError {
            onPermissionDenied()
        } catch {
            onRecordingError(error.localizedDescription)
            HapticHelper.notification(.error)
        }
    }

    static func processStoppedRecording(
        at url: URL,
        processor: ReminderProcessingService,
        modelContext: ModelContext,
        retainAudio: Bool,
        defaultList: ReminderList? = nil
    ) async {
        await processor.processRecording(
            audioURL: url,
            modelContext: modelContext,
            retainAudio: retainAudio,
            defaultList: defaultList
        )
        if processor.currentStatus == .done {
            HapticHelper.notification(.success)
        } else if processor.currentStatus == .failed {
            HapticHelper.notification(.error)
        }
    }
}

struct ActionButtonRecordingHandlers: ViewModifier {
    @Bindable var recorder: AudioRecordingService
    @Binding var actionButtonError: String?
    let startDisplayTimer: () -> Void
    let stopDisplayTimer: () -> Void
    let processStoppedRecording: (URL) async -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingStarted)) { _ in
                startDisplayTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingStopped)) { notification in
                stopDisplayTimer()
                guard let url = notification.userInfo?["audioURL"] as? URL else { return }
                Task { await processStoppedRecording(url) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingFailed)) { notification in
                actionButtonError = notification.userInfo?["message"] as? String
            }
    }
}

extension View {
    func actionButtonRecordingHandlers(
        recorder: AudioRecordingService,
        actionButtonError: Binding<String?>,
        startDisplayTimer: @escaping () -> Void,
        stopDisplayTimer: @escaping () -> Void,
        processStoppedRecording: @escaping (URL) async -> Void
    ) -> some View {
        modifier(ActionButtonRecordingHandlers(
            recorder: recorder,
            actionButtonError: actionButtonError,
            startDisplayTimer: startDisplayTimer,
            stopDisplayTimer: stopDisplayTimer,
            processStoppedRecording: processStoppedRecording
        ))
    }
}
