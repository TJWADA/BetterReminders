import SwiftUI
import SwiftData
import BetterRemindersCore

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: ReminderList
    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]

    @State private var settings = AppSettings.shared
    @Bindable private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared

    @State private var showingSettings = false
    @State private var showingTaskSearch = false
    @State private var showingAddReminder = false

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    private var listReminders: [Reminder] {
        let inList = allReminders.filter { $0.list?.id == list.id }
        return ReminderFilters.sortForListView(
            ReminderFilters.apply(
                to: inList,
                searchText: "",
                hideCompleted: settings.hideCompleted,
                priorityFilter: .all
            )
        )
    }

    private var isRecordingPresented: Binding<Bool> {
        Binding(
            get: { recorder.isRecording },
            set: { _ in }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            listHeader

            Group {
                if listReminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "checklist",
                        description: Text("Tap the keyboard or mic to add a reminder.")
                    )
                } else {
                    List {
                        ForEach(listReminders) { reminder in
                            NavigationLink {
                                ReminderDetailView(reminder: reminder)
                            } label: {
                                ReminderRowView(reminder: reminder)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingTaskSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    showingAddReminder = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }

                Button {
                    Task { await toggleRecording() }
                } label: {
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                }
                .disabled(processor.isProcessing)
                .tint(recorder.isRecording ? .red : .accentColor)

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            statusBanner
        }
        .fullScreenCover(isPresented: isRecordingPresented) {
            RecordingSheetView(
                recorder: recorder,
                displayTick: displayTick,
                onStop: { Task { await toggleRecording() } }
            )
        }
        .sheet(isPresented: $showingTaskSearch) {
            GlobalTaskSearchView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderSheet(list: list)
        }
        .alert("Microphone Access Required", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable microphone and speech recognition in Settings to record reminders.")
        }
        .alert("Recording Failed", isPresented: Binding(
            get: { actionButtonError != nil },
            set: { if !$0 { actionButtonError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionButtonError ?? "Could not start recording.")
        }
        .onAppear {
            if recorder.isRecording {
                startDisplayTimer()
            }
        }
        .actionButtonRecordingHandlers(
            recorder: recorder,
            actionButtonError: $actionButtonError,
            startDisplayTimer: startDisplayTimer,
            stopDisplayTimer: stopDisplayTimer,
            processStoppedRecording: { url in
                await RecordingFlowController.processStoppedRecording(
                    at: url,
                    processor: processor,
                    modelContext: modelContext,
                    retainAudio: settings.retainAudio,
                    defaultList: list
                )
            }
        )
    }

    @ViewBuilder
    private var statusBanner: some View {
        if !recorder.isRecording {
            if processor.isProcessing {
                ProcessingBannerView(
                    status: processor.currentStatus?.rawValue.capitalized ?? "Processing"
                )
            } else if let error = recordingError {
                RecordingErrorBannerView(message: error) {
                    recordingError = nil
                }
            }
        }
    }

    private var listHeader: some View {
        let theme = ListColorTheme(colorHex: list.colorHex)

        return HStack(spacing: 8) {
            ListTileIcon(icon: list.icon, colorHex: list.colorHex)
            Text(list.name)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.headerGradient)
    }

    private func toggleRecording() async {
        recordingError = nil
        await RecordingFlowController.toggleRecording(
            recorder: recorder,
            processor: processor,
            modelContext: modelContext,
            retainAudio: settings.retainAudio,
            defaultList: list,
            onRecordingError: { recordingError = $0 },
            onPermissionDenied: { permissionDenied = true },
            startDisplayTimer: startDisplayTimer,
            stopDisplayTimer: stopDisplayTimer
        )
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
