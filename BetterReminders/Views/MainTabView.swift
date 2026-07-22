import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.rectangle")
                }

            RecordButtonView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
