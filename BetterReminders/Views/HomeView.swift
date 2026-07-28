import SwiftUI
import SwiftData
import BetterRemindersCore

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]
    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]

    @State private var settings = AppSettings.shared
    @Bindable private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared

    @State private var groupMode: ReminderGroupMode = .byList
    @State private var sortMode: ReminderSortMode = .dueDate
    @State private var priorityFilter: PriorityFilter = .all
    @State private var searchText = ""

    @State private var showingSettings = false
    @State private var showingFilters = false
    @State private var showingDevPanel = false

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    private var filteredReminders: [Reminder] {
        ReminderFilters.sort(
            ReminderFilters.apply(
                to: allReminders,
                searchText: searchText,
                hideCompleted: settings.hideCompleted,
                priorityFilter: priorityFilter
            ),
            by: sortMode
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                reminderList
                    .safeAreaInset(edge: .top, spacing: 0) {
                        statusBanner
                    }

                cornerButtons
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(
                settings: settings,
                groupMode: $groupMode,
                sortMode: $sortMode,
                priorityFilter: $priorityFilter,
                searchText: $searchText
            )
        }
        .sheet(isPresented: $showingDevPanel) {
            DevPanelView()
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
            ListSeeder.seedIfNeeded(modelContext: modelContext)
            _ = RecordingSessionStore.consumeOpenRecordTab()
            if recorder.isRecording {
                startDisplayTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingStarted)) { _ in
            startDisplayTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingStopped)) { notification in
            stopDisplayTimer()
            guard let url = notification.userInfo?["audioURL"] as? URL else { return }
            Task { await processRecording(at: url) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .actionButtonRecordingFailed)) { notification in
            actionButtonError = notification.userInfo?["message"] as? String
        }
    }

    @ViewBuilder
    private var reminderList: some View {
        if filteredReminders.isEmpty && searchText.isEmpty && allReminders.isEmpty {
            ContentUnavailableView(
                "No Reminders",
                systemImage: "checklist",
                description: Text("Tap the mic button to record a reminder.")
            )
        } else if filteredReminders.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List {
                switch groupMode {
                case .byList:
                    listGroupedContent
                case .byDueDate:
                    dueDateGroupedContent
                }
            }
            .listStyle(.plain)
            .contentMargins(.bottom, 72, for: .scrollContent)
            .contentMargins(.top, 8, for: .scrollContent)
        }
    }

    @ViewBuilder
    private var listGroupedContent: some View {
        ForEach(lists) { list in
            let reminders = filteredReminders.filter { $0.list?.id == list.id }
            if !reminders.isEmpty {
                Section {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder)
                    }
                } header: {
                    HStack(spacing: 8) {
                        ListColorBadge(colorHex: list.colorHex, icon: list.icon)
                            .scaleEffect(0.7)
                            .frame(width: 32, height: 32)
                        Text(list.name)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var dueDateGroupedContent: some View {
        let overdue = filteredReminders.filter { ReminderFilters.isOverdue($0) }
        let today = filteredReminders.filter { ReminderFilters.isDueToday($0) }
        let upcoming = filteredReminders.filter { ReminderFilters.isUpcoming($0) }
        let noDate = filteredReminders.filter { $0.dueDate == nil && !$0.isCompleted }

        if !overdue.isEmpty {
            Section("Overdue") {
                ForEach(overdue) { reminderRow($0) }
            }
        }
        if !today.isEmpty {
            Section("Today") {
                ForEach(today) { reminderRow($0) }
            }
        }
        if !upcoming.isEmpty {
            Section("Upcoming") {
                ForEach(upcoming) { reminderRow($0) }
            }
        }
        if !noDate.isEmpty && searchText.isEmpty {
            Section("No Due Date") {
                ForEach(noDate) { reminderRow($0) }
            }
        }
    }

    @ViewBuilder
    private func reminderRow(_ reminder: Reminder) -> some View {
        NavigationLink {
            ReminderDetailView(reminder: reminder)
        } label: {
            HStack(spacing: 12) {
                ReminderRowView(reminder: reminder)
                Spacer(minLength: 0)
                if groupMode == .byDueDate, let list = reminder.list {
                    ListNameBadge(name: list.name, colorHex: list.colorHex)
                }
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if recorder.isRecording {
            HStack {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text(formattedElapsed(Int(recorder.elapsedTime)))
                    .font(.subheadline.monospacedDigit())
                Spacer()
                Text("Recording…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .id(displayTick)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        } else if processor.isProcessing {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text(processor.currentStatus?.rawValue.capitalized ?? "Processing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        } else if let error = recordingError {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                Button {
                    recordingError = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }

    private var cornerButtons: some View {
        VStack {
            HStack {
                cornerButton(icon: "ladybug.fill", color: .orange) {
                    showingDevPanel = true
                }
                Spacer()
                cornerButton(icon: "gearshape.fill", color: .secondary) {
                    showingSettings = true
                }
            }
            Spacer()
            HStack {
                cornerButton(icon: "line.3.horizontal.decrease.circle", color: .secondary) {
                    showingFilters = true
                }
                Spacer()
                recordButton
            }
        }
        .padding(20)
    }

    private func cornerButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private var recordButton: some View {
        Button {
            Task { await toggleRecording() }
        } label: {
            Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(recorder.isRecording ? Color.red : Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .disabled(processor.isProcessing)
    }

    private func toggleRecording() async {
        recordingError = nil
        RecordingSessionStore.setActionButtonArmed(false)

        if KeychainHelper.loadAPIKey()?.isEmpty ?? true {
            recordingError = "Add your OpenAI API key in Settings."
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
                stopDisplayTimer()
                await processRecording(at: url)
            } else {
                HapticHelper.recordingStarted()
                _ = try recorder.startRecording()
                startDisplayTimer()
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
            retainAudio: settings.retainAudio
        )
        if processor.currentStatus == .done {
            HapticHelper.notification(.success)
        } else if processor.currentStatus == .failed {
            HapticHelper.notification(.error)
        }
    }

    private func formattedElapsed(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
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
    HomeView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
