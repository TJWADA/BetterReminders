import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var settings = AppSettings.shared
    @State private var showingOnboarding = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

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
        .onAppear {
            if !settings.hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
