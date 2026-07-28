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
    @State private var showingDevPanel = false
    @State private var showingAddReminder = false

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    @Namespace private var recordingNamespace
    @Namespace private var searchNamespace

    @State private var safeAreaBottom: CGFloat = 34

    private let fadeExtension: CGFloat = 48

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
            .scrollClipDisabled()
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            ScrollEdgeFade(isTop: false)
                .frame(height: safeAreaBottom + 76 + fadeExtension)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 76)
        }
        .overlay(alignment: .bottom) {
            bottomActionBar
        }
        .onGeometryChange(for: EdgeInsets.self, of: { $0.safeAreaInsets }) { insets in
            safeAreaBottom = insets.bottom
        }
        .overlay {
            if recorder.isRecording {
                RecordingExpandedOverlay(
                    recorder: recorder,
                    displayTick: displayTick,
                    namespace: recordingNamespace,
                    onStop: { Task { await toggleRecording() } }
                )
                .transition(.identity)
                .zIndex(2)
            }

            if showingTaskSearch {
                GlobalTaskSearchOverlay(
                    isPresented: $showingTaskSearch,
                    namespace: searchNamespace
                )
                .transition(.identity)
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: recorder.isRecording)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: showingTaskSearch)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDevPanel) {
            DevPanelView()
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

    private var listHeader: some View {
        let theme = ListColorTheme(colorHex: list.colorHex)

        return HStack(spacing: 8) {
            ListHeaderIcon(icon: list.icon, colorHex: list.colorHex, size: 26)
            Text(list.name)
                .font(.headline)
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.headerGradient)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
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

            HStack {
                CornerActionButton(
                    icon: "magnifyingglass",
                    namespace: searchNamespace,
                    geometryID: "searchExpand",
                    isExpanded: showingTaskSearch
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        showingTaskSearch = true
                    }
                }
                Spacer()
                CornerActionButton(icon: "square.and.pencil", color: .accentColor) {
                    showingAddReminder = true
                }
                RecordButtonView(
                    recorder: recorder,
                    isProcessing: processor.isProcessing,
                    namespace: recordingNamespace,
                    isExpanded: recorder.isRecording
                ) {
                    Task { await toggleRecording() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func toggleRecording() async {
        recordingError = nil

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
            retainAudio: settings.retainAudio,
            defaultList: list
        )
        if processor.currentStatus == .done {
            HapticHelper.notification(.success)
        } else if processor.currentStatus == .failed {
            HapticHelper.notification(.error)
        }
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
