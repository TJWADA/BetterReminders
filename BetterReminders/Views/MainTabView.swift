import SwiftUI
import SwiftData
import BetterRemindersCore

enum AppTab: Hashable {
    case today
    case lists
    case record
    case settings
}

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var settings = AppSettings.shared
    @State private var showingOnboarding = false
    @State private var actionButtonError: String?
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(AppTab.today)

            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.lists)

            RecordButtonView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(AppTab.record)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .onAppear {
            if !settings.hasCompletedOnboarding {
                showingOnboarding = true
            }
            selectRecordTabIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                selectRecordTabIfNeeded()
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingFailed)) { notification in
            actionButtonError = notification.userInfo?["message"] as? String
        }
        .alert("Recording Failed", isPresented: Binding(
            get: { actionButtonError != nil },
            set: { if !$0 { actionButtonError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionButtonError ?? "Could not start recording from the Action Button.")
        }
    }

    private func selectRecordTabIfNeeded() {
        guard RecordingSessionStore.consumeOpenRecordTab() else { return }
        selectedTab = .record
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
