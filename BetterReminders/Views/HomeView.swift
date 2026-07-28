import SwiftUI
import SwiftData
import BetterRemindersCore

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderList.sortOrder) private var lists: [ReminderList]

    @State private var settings = AppSettings.shared
    @Bindable private var recorder = AudioRecordingService.shared
    @State private var processor = ReminderProcessingService.shared

    @State private var showingSettings = false
    #if DEBUG
    @State private var showingDevPanel = false
    #endif
    @State private var showingNewList = false
    @State private var showingTaskSearch = false
    @State private var editingList: ReminderList?

    @State private var displayTick = 0
    @State private var displayTimer: Timer?
    @State private var permissionDenied = false
    @State private var recordingError: String?
    @State private var actionButtonError: String?

    @Namespace private var listTransitionNamespace
    @Namespace private var recordingNamespace
    @Namespace private var searchNamespace

    @State private var navigationPath = NavigationPath()

    @State private var listGridID = UUID()

    private let gridSpacing: CGFloat = 12

    private let fadeExtension: CGFloat = 48

    private let cornerPadding: CGFloat = 20

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                ScrollView {
                    listGrid
                        .id(listGridID)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .scrollClipDisabled()
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: 60)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 76)
                }

                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ScrollEdgeFade(isTop: true)
                            .frame(height: geometry.safeAreaInsets.top + 60 + fadeExtension)
                        Spacer(minLength: 0)
                        ScrollEdgeFade(isTop: false)
                            .frame(height: geometry.safeAreaInsets.bottom + 76 + fadeExtension)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    cornerActionButtons
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ReminderList.self) { list in
                ListDetailView(list: list)
                    .navigationTransition(.zoom(sourceID: list.id, in: listTransitionNamespace))
                    .onDisappear {
                        listGridID = UUID()
                    }
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
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        #if DEBUG
        .sheet(isPresented: $showingDevPanel) {
            DevPanelView()
        }
        #endif
        .sheet(isPresented: $showingNewList) {
            ListEditView()
        }
        .onChange(of: showingNewList) { _, isShowing in
            if !isShowing {
                listGridID = UUID()
            }
        }
        .sheet(item: $editingList) { list in
            ListEditCompactView(list: list)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
                    retainAudio: settings.retainAudio
                )
            }
        )
    }

    private var listGrid: some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<(lists.count / 2), id: \.self) { row in
                HStack(alignment: .top, spacing: gridSpacing) {
                    listTile(at: row * 2)
                        .frame(maxWidth: .infinity)
                    listTile(at: row * 2 + 1)
                        .frame(maxWidth: .infinity)
                }
            }

            if !showingTaskSearch {
                if lists.count.isMultiple(of: 2) == false, !lists.isEmpty {
                    HStack(alignment: .top, spacing: gridSpacing) {
                        listTile(for: lists[lists.count - 1])
                            .frame(maxWidth: .infinity)
                        EmptyListGridCell()
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack(alignment: .top, spacing: gridSpacing) {
                    addListTileButton
                        .frame(maxWidth: .infinity, alignment: .leading)
                    EmptyListGridCell()
                        .frame(maxWidth: .infinity)
                }
            } else if lists.count.isMultiple(of: 2) == false, !lists.isEmpty {
                HStack(alignment: .top, spacing: gridSpacing) {
                    listTile(for: lists[lists.count - 1])
                        .frame(maxWidth: .infinity)
                    EmptyListGridCell()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func listTile(at index: Int) -> some View {
        listTile(for: lists[index])
    }

    private func listTile(for list: ReminderList) -> some View {
        Button {
            navigationPath.append(list)
        } label: {
            ListIconTile(list: list)
                .matchedTransitionSource(id: list.id, in: listTransitionNamespace)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.4) {
            HapticHelper.selection()
            editingList = list
        }
    }

    private var addListTileButton: some View {
        Button {
            showingNewList = true
        } label: {
            AddListTile()
        }
        .buttonStyle(.plain)
    }

    private var cornerActionButtons: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                #if DEBUG
                CornerActionButton(icon: "ladybug.fill", color: .orange) {
                    showingDevPanel = true
                }
                #endif
                Spacer(minLength: 0)
                CornerActionButton(icon: "gearshape.fill") {
                    showingSettings = true
                }
            }

            Spacer(minLength: 0)

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

                HStack(spacing: 0) {
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
                    Spacer(minLength: 0)
                    RecordButtonView(
                        recorder: recorder,
                        isProcessing: processor.isProcessing,
                        namespace: recordingNamespace,
                        isExpanded: recorder.isRecording
                    ) {
                        Task { await toggleRecording() }
                    }
                }
            }
        }
        .padding(cornerPadding)
    }

    private func toggleRecording() async {
        recordingError = nil
        await RecordingFlowController.toggleRecording(
            recorder: recorder,
            processor: processor,
            modelContext: modelContext,
            retainAudio: settings.retainAudio,
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

#Preview {
    HomeView()
        .modelContainer(for: [Reminder.self, ReminderList.self, ProcessingJob.self], inMemory: true)
}
