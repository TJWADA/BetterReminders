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
    @State private var movingReminder: Reminder?

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var listRefreshTick = 0
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    @State private var newReminderTitle = ""
    @State private var isComposingNewReminder = false
    @State private var seenPlacementIDs: Set<UUID> = []
    @State private var dropTargetID: UUID?
    @State private var isNewReminderDropTargeted = false

    private var remindersInList: [Reminder] {
        _ = listRefreshTick
        return allReminders.filter { $0.list?.id == list.id }
    }

    private var listReminders: [Reminder] {
        ReminderFilters.sortForListView(
            ReminderFilters.visibleInList(remindersInList)
        )
    }

    private var remindersByID: [UUID: Reminder] {
        Dictionary(uniqueKeysWithValues: remindersInList.map { ($0.id, $0) })
    }

    private var isRecordingPresented: Binding<Bool> {
        Binding(
            get: { recorder.isRecording },
            set: { _ in }
        )
    }

    var body: some View {
        ReminderListTableView(
            reminders: listReminders,
            dropTargetID: dropTargetID,
            isComposerDropTargeted: isNewReminderDropTargeted,
            refreshToken: listRefreshTick,
            newReminderTitle: $newReminderTitle,
            isComposingNewReminder: $isComposingNewReminder,
            onDropTargetChange: { dropTargetID = $0 },
            onComposerDropTargetChange: { isNewReminderDropTargeted = $0 },
            onCompletionChanged: scheduleGraceRefresh,
            onCollapseChanged: persistListChange,
            onBecameVisible: { reminder in
                if reminder.needsManualSort {
                    seenPlacementIDs.insert(reminder.id)
                }
            },
            onEdit: { editingReminder = $0 },
            onMove: { movingReminder = $0 },
            onDrop: handleDrop,
            onDropAtEnd: handleDropAtEnd,
            onCommitNewReminder: commitNewReminder,
            onComposerFocusLost: handleComposerFocusLost
        )
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
        .sheet(item: $movingReminder) { reminder in
            ReminderMoveListSheet(reminder: reminder) {
                persistListChange()
            }
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
            Reminder.backfillTopLevelSortOrder(from: remindersInList)
            try? modelContext.save()
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

    private func persistListChange() {
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

        let reminder = Reminder(
            title: trimmed,
            list: list,
            subtaskSortOrder: Reminder.nextTopLevelSortOrder(from: remindersInList)
        )
        modelContext.insert(reminder)
        try? modelContext.save()
        newReminderTitle = ""
        HapticHelper.selection()
        listRefreshTick += 1
    }

    private func handleComposerFocusLost() {
        let trimmed = newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            commitNewReminder()
        } else {
            newReminderTitle = ""
        }
        isComposingNewReminder = false
    }

    private func handleDrop(
        _ payloads: [String],
        onto target: Reminder,
        zone: ReminderDropZone
    ) -> Bool {
        guard let dragged = draggedReminder(from: payloads) else { return false }
        let topLevel = Reminder.orderedTopLevel(from: remindersInList)
        guard let action = ReminderDropResolver.action(
            dragging: dragged,
            droppingOn: target,
            zone: zone,
            visible: listReminders
        ) else { return false }

        let applied = dragged.apply(action, topLevel: topLevel)
        if applied {
            HapticHelper.selection()
            persistListChange()
        }
        dropTargetID = nil
        return applied
    }

    private func handleDropAtEnd(_ payloads: [String]) -> Bool {
        guard let dragged = draggedReminder(from: payloads) else { return false }
        let topLevel = Reminder.orderedTopLevel(from: remindersInList)
        let applied = dragged.apply(.move(under: nil, before: nil), topLevel: topLevel)
        if applied {
            HapticHelper.selection()
            persistListChange()
        }
        isNewReminderDropTargeted = false
        return applied
    }

    private func draggedReminder(from payloads: [String]) -> Reminder? {
        guard let raw = payloads.first, let id = UUID(uuidString: raw) else { return nil }
        return remindersByID[id]
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

private struct ReminderMoveListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReminderList.sortOrder) private var allLists: [ReminderList]
    @Bindable var reminder: Reminder
    var onMoved: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(allLists) { list in
                    Button {
                        move(to: list)
                    } label: {
                        HStack {
                            Label {
                                Text(list.name)
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: list.icon)
                                    .foregroundStyle(Color(hex: list.colorHex))
                            }
                            Spacer()
                            if reminder.list?.id == list.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func move(to list: ReminderList) {
        if reminder.list?.id != list.id {
            reminder.list = list
            reminder.syncSubtasksList()
            onMoved()
        }
        dismiss()
    }
}
