import SwiftUI
import UIKit

struct ReminderListTableView: UIViewControllerRepresentable {
    var reminders: [Reminder]
    var dropTargetID: UUID?
    var isComposerDropTargeted: Bool
    var refreshToken: Int
    @Binding var newReminderTitle: String
    @Binding var isComposingNewReminder: Bool
    var onDropTargetChange: (UUID?) -> Void
    var onComposerDropTargetChange: (Bool) -> Void
    var onCompletionChanged: () -> Void
    var onCollapseChanged: () -> Void
    var onBecameVisible: (Reminder) -> Void
    var onEdit: (Reminder) -> Void
    var onMove: (Reminder) -> Void
    var onDrop: ([String], Reminder, ReminderDropZone) -> Bool
    var onDropAtEnd: ([String]) -> Bool
    var onCommitNewReminder: () -> Void
    var onComposerFocusLost: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ReminderListTableController {
        let controller = ReminderListTableController()
        let tableView = controller.tableView
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.dragDelegate = context.coordinator
        tableView.dropDelegate = context.coordinator
        context.coordinator.attach(to: tableView)
        return controller
    }

    func updateUIViewController(_ controller: ReminderListTableController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        guard !coordinator.isDragging else { return }

        let ids = reminders.map(\.id)
        let showsComposer = isComposingNewReminder || !newReminderTitle.isEmpty
        let shouldReload =
            coordinator.displayedIDs != ids
            || coordinator.displayedDropTargetID != dropTargetID
            || coordinator.displayedComposerTargeted != isComposerDropTargeted
            || coordinator.displayedRefreshToken != refreshToken
            || coordinator.displayedShowsComposer != showsComposer

        coordinator.displayedIDs = ids
        coordinator.displayedDropTargetID = dropTargetID
        coordinator.displayedComposerTargeted = isComposerDropTargeted
        coordinator.displayedRefreshToken = refreshToken
        coordinator.displayedShowsComposer = showsComposer

        if shouldReload {
            controller.tableView.reloadData()
        }
    }

    final class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate, UIGestureRecognizerDelegate {
        var parent: ReminderListTableView
        weak var tableView: UITableView?
        var isDragging = false
        var displayedIDs: [UUID] = []
        var displayedDropTargetID: UUID?
        var displayedComposerTargeted = false
        var displayedRefreshToken = -1
        var displayedShowsComposer = false
        private var pendingZone: ReminderDropZone = .onto
        private var suppressFocusLostUntil: Date?

        init(parent: ReminderListTableView) {
            self.parent = parent
        }

        func attach(to tableView: UITableView) {
            self.tableView = tableView
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTableTap(_:)))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            tableView.addGestureRecognizer(tap)
        }

        private var reminders: [Reminder] { parent.reminders }
        private var composerIndex: Int { reminders.count }
        private var showsComposer: Bool {
            parent.isComposingNewReminder || !parent.newReminderTitle.isEmpty
        }

        func numberOfSections(in tableView: UITableView) -> Int { 1 }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            reminders.count + (showsComposer ? 1 : 0)
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if indexPath.row >= reminders.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: ReminderListTableController.composerID, for: indexPath)
                cell.selectionStyle = .none
                cell.backgroundColor = displayedComposerTargeted
                    ? UIColor.systemIndigo.withAlphaComponent(0.12)
                    : .systemBackground
                cell.contentConfiguration = UIHostingConfiguration {
                    NewReminderComposerRow(
                        title: parent.$newReminderTitle,
                        onSubmit: { [weak self] in self?.handleComposerSubmit() },
                        onFocusLost: { [weak self] in self?.handleComposerFocusLost() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .margins(.all, 0)
                return cell
            }

            let reminder = reminders[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: ReminderListTableController.reminderID, for: indexPath)
            cell.selectionStyle = .none
            cell.backgroundColor = .systemBackground
            cell.contentConfiguration = UIHostingConfiguration {
                ReminderRowView(
                    reminder: reminder,
                    indentLevel: reminder.isSubtask ? 1 : 0,
                    isDropTargeted: displayedDropTargetID == reminder.id,
                    onCompletionChanged: parent.onCompletionChanged,
                    onCollapseChanged: parent.onCollapseChanged,
                    onBecameVisible: { [self] in parent.onBecameVisible(reminder) },
                    onEdit: { [self] in parent.onEdit(reminder) }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: reminder.dueDate) { _, _ in
                    Task { await NotificationSchedulingService.schedule(for: reminder) }
                }
            }
            .margins(.all, 0)
            return cell
        }

        func tableView(
            _ tableView: UITableView,
            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {
            guard indexPath.row < reminders.count else { return nil }
            let reminder = reminders[indexPath.row]
            guard !reminder.isSubtask else { return nil }
            let move = UIContextualAction(style: .normal, title: "Move") { [weak self] _, _, completion in
                self?.parent.onMove(reminder)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [move])
        }

        func tableView(
            _ tableView: UITableView,
            itemsForBeginning session: UIDragSession,
            at indexPath: IndexPath
        ) -> [UIDragItem] {
            guard indexPath.row < reminders.count else { return [] }
            let reminder = reminders[indexPath.row]
            let id = reminder.id.uuidString
            let item = UIDragItem(itemProvider: NSItemProvider(object: id as NSString))
            item.localObject = id
            item.previewProvider = {
                let label = UILabel()
                label.text = reminder.title
                label.font = .preferredFont(forTextStyle: .body)
                label.numberOfLines = 1
                label.textAlignment = .center
                label.backgroundColor = .secondarySystemBackground
                label.layer.cornerRadius = 8
                label.layer.masksToBounds = true
                label.frame = CGRect(x: 0, y: 0, width: 220, height: 36)
                return UIDragPreview(view: label)
            }
            return [item]
        }

        func tableView(
            _ tableView: UITableView,
            dragSessionWillBegin session: UIDragSession
        ) {
            isDragging = true
        }

        func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
            isDragging = false
            clearHighlights(in: tableView)
            displayedIDs = parent.reminders.map(\.id)
            displayedRefreshToken = parent.refreshToken
            displayedShowsComposer = parent.isComposingNewReminder || !parent.newReminderTitle.isEmpty
            tableView.reloadData()
        }

        func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
            session.localDragSession != nil
        }

        func tableView(
            _ tableView: UITableView,
            dropSessionDidUpdate session: UIDropSession,
            withDestinationIndexPath destinationIndexPath: IndexPath?
        ) -> UITableViewDropProposal {
            guard draggedID(from: session) != nil else {
                return UITableViewDropProposal(operation: .forbidden)
            }

            let location = session.location(in: tableView)
            let hitPath = tableView.indexPathForRow(at: location) ?? destinationIndexPath

            guard let hitPath else {
                pendingZone = .after
                setHighlights(dropTarget: nil, composer: true, in: tableView)
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }

            if hitPath.row >= reminders.count {
                pendingZone = .after
                setHighlights(dropTarget: nil, composer: true, in: tableView)
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }

            let target = reminders[hitPath.row]
            if let dragged = draggedReminder(from: session), target.parent?.id == dragged.id {
                setHighlights(dropTarget: nil, composer: false, in: tableView)
                return UITableViewDropProposal(operation: .forbidden)
            }

            var zone = ReminderDropZone.onto
            if let cell = tableView.cellForRow(at: hitPath) {
                let point = tableView.convert(location, to: cell)
                zone = ReminderDropResolver.zone(y: point.y, height: cell.bounds.height)
            }
            pendingZone = zone

            switch zone {
            case .onto:
                setHighlights(dropTarget: target.id, composer: false, in: tableView)
                return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
            case .before, .after:
                setHighlights(dropTarget: nil, composer: false, in: tableView)
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        }

        func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
            clearHighlights(in: tableView)
        }

        func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
            clearHighlights(in: tableView)
        }

        func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
            let payloads = dragPayloads(from: coordinator)
            defer { clearHighlights(in: tableView) }

            let location = coordinator.session.location(in: tableView)
            let hitPath = tableView.indexPathForRow(at: location) ?? coordinator.destinationIndexPath

            guard let hitPath, hitPath.row < reminders.count else {
                _ = parent.onDropAtEnd(payloads)
                return
            }

            let target = reminders[hitPath.row]
            var zone = pendingZone
            if coordinator.proposal.intent == .insertIntoDestinationIndexPath {
                zone = .onto
            } else if let cell = tableView.cellForRow(at: hitPath) {
                let point = tableView.convert(location, to: cell)
                zone = ReminderDropResolver.zone(y: point.y, height: cell.bounds.height)
            }

            _ = parent.onDrop(payloads, target, zone)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        @objc private func handleTableTap(_ gesture: UITapGestureRecognizer) {
            guard !isDragging, let tableView else { return }
            let location = gesture.location(in: tableView)
            guard tableView.indexPathForRow(at: location) == nil else { return }
            if parent.isComposingNewReminder {
                parent.onComposerFocusLost()
                return
            }
            parent.isComposingNewReminder = true
        }

        private func handleComposerSubmit() {
            let trimmed = parent.newReminderTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                parent.onComposerFocusLost()
                return
            }
            suppressFocusLostUntil = Date().addingTimeInterval(0.3)
            parent.onCommitNewReminder()
        }

        private func handleComposerFocusLost() {
            if let until = suppressFocusLostUntil, Date() < until { return }
            guard parent.isComposingNewReminder || !parent.newReminderTitle.isEmpty else { return }
            parent.onComposerFocusLost()
        }

        private func setHighlights(dropTarget: UUID?, composer: Bool, in tableView: UITableView) {
            let previousTarget = displayedDropTargetID
            let previousComposer = displayedComposerTargeted
            displayedDropTargetID = dropTarget
            displayedComposerTargeted = composer
            parent.onDropTargetChange(dropTarget)
            parent.onComposerDropTargetChange(composer)

            var paths: [IndexPath] = []
            if let previousTarget, let index = reminders.firstIndex(where: { $0.id == previousTarget }) {
                paths.append(IndexPath(row: index, section: 0))
            }
            if let dropTarget, previousTarget != dropTarget, let index = reminders.firstIndex(where: { $0.id == dropTarget }) {
                paths.append(IndexPath(row: index, section: 0))
            }
            if previousComposer != composer, showsComposer {
                paths.append(IndexPath(row: composerIndex, section: 0))
            }
            let unique = Array(Set(paths)).filter { tableView.numberOfRows(inSection: 0) > $0.row }
            if !unique.isEmpty {
                tableView.reconfigureRows(at: unique)
            }
        }

        private func clearHighlights(in tableView: UITableView) {
            setHighlights(dropTarget: nil, composer: false, in: tableView)
        }

        private func draggedID(from session: UIDropSession) -> String? {
            if let local = session.localDragSession?.items.first?.localObject as? String {
                return local
            }
            return nil
        }

        private func draggedReminder(from session: UIDropSession) -> Reminder? {
            guard let raw = draggedID(from: session), let id = UUID(uuidString: raw) else { return nil }
            return reminders.first { $0.id == id }
        }

        private func dragPayloads(from coordinator: UITableViewDropCoordinator) -> [String] {
            if let local = coordinator.items.first?.dragItem.localObject as? String {
                return [local]
            }
            if let local = coordinator.session.localDragSession?.items.first?.localObject as? String {
                return [local]
            }
            return []
        }
    }
}

final class ReminderListTableController: UIViewController {
    static let reminderID = "ReminderCell"
    static let composerID = "ComposerCell"

    let tableView = UITableView(frame: .zero, style: .plain)

    override func loadView() {
        tableView.translatesAutoresizingMaskIntoConstraints = true
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.reminderID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.composerID)
        tableView.dragInteractionEnabled = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.keyboardDismissMode = .interactive
        tableView.backgroundColor = .systemBackground
        view = tableView
    }
}

private struct NewReminderComposerRow: View {
    @Binding var title: String
    var onSubmit: () -> Void
    var onFocusLost: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .font(.title3)

            TextField("New Reminder", text: $title)
                .focused($isFocused)
                .onAppear { isFocused = true }
                .onSubmit {
                    let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    onSubmit()
                    isFocused = hasTitle
                }
                .onChange(of: isFocused) { _, focused in
                    guard !focused else { return }
                    onFocusLost()
                }
        }
        .padding(.vertical, 2)
    }
}
