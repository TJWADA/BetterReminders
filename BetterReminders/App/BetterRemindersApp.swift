import SwiftUI
import SwiftData
import UserNotifications
import BetterRemindersCore

@main
struct BetterRemindersApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let modelContainer: ModelContainer

    init() {
        RecordingSessionStore.clearActionButtonState()
        do {
            modelContainer = try ModelContainer(for: Reminder.self, ReminderList.self, ProcessingJob.self)
            BackgroundRecordingProcessor.register()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    Task {
                        await ActionButtonRecordingHandler.continueFromAppOpenIfNeeded()
                        await requestNotificationPermission()
                        ListSeeder.seedIfNeeded(modelContext: modelContainer.mainContext)
                        await syncNotificationsAndCleanup()
                        await processPendingRecordings()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .recordingDidFinish)) { _ in
                    Task {
                        await processPendingRecordings()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .actionButtonOpenRecordingRequested)) { _ in
                    Task {
                        await ActionButtonRecordingHandler.continueFromAppOpenIfNeeded()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await ActionButtonRecordingHandler.continueFromAppOpenIfNeeded()
                            await syncNotificationsAndCleanup()
                            await processPendingRecordings()
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    @MainActor
    private func syncNotificationsAndCleanup() async {
        ProcessingJobCleanupService.cleanup(modelContext: modelContainer.mainContext)
        if let reminders = try? modelContainer.mainContext.fetch(FetchDescriptor<Reminder>()) {
            await NotificationSchedulingService.rescheduleAll(reminders: reminders)
        }
    }

    @MainActor
    private func processPendingRecordings() async {
        await BackgroundRecordingProcessor.processAllPending()
    }
}
