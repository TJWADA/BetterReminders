import AppIntents

struct BetterRemindersShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleRecordingIntent(),
            phrases: [
                "Toggle recording in \(.applicationName)",
                "Record reminder in \(.applicationName)",
                "Open and record in \(.applicationName)",
            ],
            shortTitle: "Toggle Recording",
            systemImageName: "mic.fill"
        )
    }
}
