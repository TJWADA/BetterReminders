import SwiftUI
import SwiftData
import BetterRemindersCore

struct ListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: ReminderList
    @Query private var allReminders: [Reminder]

    @State private var settings = AppSettings.shared
    @Bindable private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared

    @State private var showingSettings = false
    @State private var showingTaskSearch = false
    @State private var editingReminder: Reminder?

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var listRefreshTick = 0
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    @State private var newReminderTitle = ""
    @FocusState private var isNewReminderFocused: Bool
    @State private var seenPlacementIDs: Set<UUID> = []

    private var listReminders: [Reminder] {
        _ = listRefreshTick
        let inList = allReminders.filter { $0.list?.id == list.id }
        return ReminderFilters.sortForListView(
            ReminderFilters.visibleInList(inList)
        )
    }

    private var isRecordingPresented: Binding<Bool> {
        Binding(
            get: { recorder.isRecording },
            set: { _ in }
        )
    }

    var body: some View {
        List {
            ForEach(Array(listReminders.enumerated()), id: \.element.id) { index, reminder in
                ReminderRowView(
                    reminder: reminder,
                    indentLevel: reminder.isSubtask ? 1 : 0,
                    onCompletionChanged: {
                        scheduleGraceRefresh()
                    },
                    onBecameVisible: {
                        if reminder.needsManualSort {
                            seenPlacementIDs.insert(reminder.id)
                        }
                    }
                )
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if reminder.isSubtask {
                        Button("Outdent") {
                            reminder.outdent()
                            HapticHelper.selection()
                            persistSubtaskChange()
                        }
                        .tint(.orange)
                    } else {
                        let preceding = index > 0 ? listReminders[index - 1] : nil
                        if reminder.canIndent(preceding: preceding) {
                            Button("Indent") {
                                reminder.indent(preceding: preceding)
                                HapticHelper.selection()
                                persistSubtaskChange()
                            }
                            .tint(.indigo)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Edit") {
                        editingReminder = reminder
                    }
                    .tint(.accentColor)
                }
                .onChange(of: reminder.dueDate) { _, _ in
                    Task { await NotificationSchedulingService.schedule(for: reminder) }
                }
            }

            newReminderRow
        }
        .listStyle(.plain)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingTaskSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
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
        .sheet(item: $editingReminder) { reminder in
            ReminderDetailView(reminder: reminder)
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
        .onDisappear {
            confirmSeenPlacements()
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

    private var newReminderRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.title3)

            TextField("New Reminder", text: $newReminderTitle)
                .focused($isNewReminderFocused)
                .onSubmit {
                    commitNewReminder()
                }
        }
        .padding(.vertical, 2)
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

    private func persistSubtaskChange() {
        listRefreshTick += 1
        try? modelContext.save()
    }

    private func confirmSeenPlacements() {
        PlacementReview.confirmVisiblePlacements(ids: seenPlacementIDs, in: allReminders)
        try? modelContext.save()
    }

    private func commitNewReminder() {
        let trimmed = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let reminder = Reminder(title: trimmed, list: list)
        modelContext.insert(reminder)
        try? modelContext.save()
        newReminderTitle = ""
        HapticHelper.selection()
        isNewReminderFocused = true
    }

    private func scheduleGraceRefresh() {
        listRefreshTick += 1
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(ReminderFilters.completionGracePeriod))
            listRefreshTick += 1
            try? modelContext.save()
        }
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
