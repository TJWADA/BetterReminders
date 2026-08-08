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

    @State private var navigationPath = NavigationPath()

    private let gridSpacing: CGFloat = 12

    private var isRecordingPresented: Binding<Bool> {
        Binding(
            get: { recorder.isRecording },
            set: { _ in }
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                listGrid
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .navigationTitle("Lists")
            .navigationDestination(for: ReminderList.self) { list in
                ListDetailView(list: list)
            }
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingDevPanel = true
                    } label: {
                        Image(systemName: "ladybug.fill")
                            .foregroundStyle(.orange)
                    }
                }
                #endif
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
        #if DEBUG
        .sheet(isPresented: $showingDevPanel) {
            DevPanelView()
        }
        #endif
        .sheet(isPresented: $showingNewList) {
            ListEditView()
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
        }
    }

    private func listTile(at index: Int) -> some View {
        listTile(for: lists[index])
    }

    private func listTile(for list: ReminderList) -> some View {
        ListIconTile(list: list)
            .contentShape(Rectangle())
            .onTapGesture {
                navigationPath.append(list)
            }
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
