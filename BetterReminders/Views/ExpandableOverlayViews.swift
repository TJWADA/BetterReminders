import SwiftUI
import SwiftData
import BetterRemindersCore

// MARK: - Recording Expanded Overlay

struct RecordingExpandedOverlay: View {
    @Bindable var recorder: AudioRecordingService
    var displayTick: Int
    var namespace: Namespace.ID
    var onStop: () -> Void

    @State private var contentVisible = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: contentVisible ? 0 : 28, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay {
                    LinearGradient(
                        colors: [Color.red.opacity(0.10), Color.red.opacity(0.03), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                }
                .matchedGeometryEffect(id: "recordingExpand", in: namespace)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
                        RecordingWaveformBars(
                            level: recorder.currentAudioLevel(),
                            barCount: 21,
                            color: .red
                        )
                        .frame(height: 72)
                    }

                    Text(formattedElapsed)
                        .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .id(displayTick)

                    Text("Recording")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.red)
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 20)

                Spacer()

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.red.gradient, in: Circle())
                        .shadow(color: .red.opacity(0.4), radius: 16, y: 4)
                }
                .matchedGeometryEffect(id: "recordButton", in: namespace)
                .padding(.bottom, 52)
            }

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.6))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                        .opacity(contentVisible ? 1 : 0)
                        .padding(.top, 8)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.12)) {
                contentVisible = true
            }
        }
        .onDisappear {
            contentVisible = false
        }
    }

    private var formattedElapsed: String {
        let seconds = Int(recorder.elapsedTime)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Global Task Search Overlay

struct GlobalTaskSearchOverlay: View {
    @Binding var isPresented: Bool
    var namespace: Namespace.ID

    @Query(sort: \Reminder.createdAt, order: .reverse) private var allReminders: [Reminder]
    @State private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var sortMode: ReminderSortMode = .dueDate
    @State private var priorityFilter: PriorityFilter = .all
    @FocusState private var searchFocused: Bool
    @State private var contentVisible = false

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
        ZStack {
            RoundedRectangle(cornerRadius: contentVisible ? 0 : 22, style: .continuous)
                .fill(Color(.systemBackground))
                .matchedGeometryEffect(id: "searchExpand", in: namespace)
                .ignoresSafeArea()

            NavigationStack {
                VStack(spacing: 0) {
                    searchHeader
                    sortBar
                    resultsList
                }
                .opacity(contentVisible ? 1 : 0)
                .offset(y: contentVisible ? 0 : 16)
            }
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                searchFocused = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.12)) {
                contentVisible = true
            }
        }
        .onDisappear {
            contentVisible = false
            searchText = ""
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tasks", text: $searchText)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                dismissSearch()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.secondary.opacity(0.1), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var sortBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReminderSortMode.allCases) { mode in
                    SortChip(
                        label: mode.label,
                        isSelected: sortMode == mode
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortMode = mode
                        }
                    }
                }

                Menu {
                    Picker("Priority", selection: $priorityFilter) {
                        ForEach(PriorityFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    Toggle("Hide Completed", isOn: $settings.hideCompleted)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("Filter")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var resultsList: some View {
        if filteredReminders.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(filteredReminders) { reminder in
                    NavigationLink {
                        ReminderDetailView(reminder: reminder)
                    } label: {
                        GlobalSearchReminderRow(reminder: reminder)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func dismissSearch() {
        searchFocused = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            contentVisible = false
            isPresented = false
        }
    }
}

struct SortChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .secondary)
        }
    }
}

struct GlobalSearchReminderRow: View {
    @Bindable var reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let list = reminder.list {
                        ListNameBadge(name: list.name, colorHex: list.colorHex)
                    }
                    if reminder.priority > 0 {
                        Text(reminder.priorityLabel)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(priorityColor)
                    }
                    if let dueDate = reminder.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(ReminderFilters.isOverdue(reminder) ? .red : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var priorityColor: Color {
        switch reminder.priority {
        case 3: return .red
        case 2: return .orange
        case 1: return .blue
        default: return .secondary
        }
    }
}
