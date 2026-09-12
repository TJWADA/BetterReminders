import Foundation
import SwiftData

enum SpokenSortKind: String {
    case clear
    case borderline
    case catchAll
    case split
}

struct SpokenSortListSpec: Equatable {
    let name: String
    let icon: String
    let colorHex: String
    let description: String
}

struct SpokenSortUtterance: Equatable, Identifiable {
    let id: Int
    let say: String
    let expectedLists: [String]
    let kind: SpokenSortKind
}

struct SpokenSortPreset: Equatable, Identifiable {
    let id: String
    let name: String
    let summary: String
    let lists: [SpokenSortListSpec]
    let utterances: [SpokenSortUtterance]
}

struct SpokenSortResult: Identifiable {
    let id: String
    let say: String
    let expectedLists: [String]
    let actualLists: [String]
    let actualTitles: [String]
    let kind: SpokenSortKind
    let errorMessage: String?

    var passed: Bool {
        errorMessage == nil
            && SpokenSortTestScript.score(expected: expectedLists, actual: actualLists)
    }
}

enum SpokenSortTestScript {
    static func score(expected: [String], actual: [String]) -> Bool {
        let expectedSet = Set(expected.map { $0.lowercased() })
        let actualSet = Set(actual.map { $0.lowercased() })
        return !expectedSet.isEmpty && expectedSet == actualSet
    }

    @MainActor
    static func prepareLists(_ preset: SpokenSortPreset, modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
        let fixtureNames = Set(preset.lists.map { $0.name.lowercased() })

        for (index, spec) in preset.lists.enumerated() {
            if let match = ListSeeder.findList(named: spec.name, in: existing) {
                match.name = spec.name
                match.icon = spec.icon
                match.colorHex = spec.colorHex
                match.sortOrder = index
                match.isDefault = spec.name == "General"
                match.listDescription = spec.description
            } else {
                let list = ReminderList(
                    name: spec.name,
                    icon: spec.icon,
                    colorHex: spec.colorHex,
                    sortOrder: index,
                    isDefault: spec.name == "General",
                    listDescription: spec.description
                )
                modelContext.insert(list)
            }
        }

        for extra in existing where !fixtureNames.contains(extra.name.lowercased()) {
            modelContext.delete(extra)
        }
        try? modelContext.save()

        let remaining = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
        for list in remaining {
            for reminder in list.reminders {
                modelContext.delete(reminder)
            }
        }
        try? modelContext.save()
    }

    @MainActor
    static func run(
        preset: SpokenSortPreset,
        modelContext: ModelContext,
        processor: ReminderProcessingService,
        onProgress: (Int, Int, String) -> Void
    ) async -> [SpokenSortResult] {
        prepareLists(preset, modelContext: modelContext)

        var results: [SpokenSortResult] = []
        for (index, utterance) in preset.utterances.enumerated() {
            onProgress(index + 1, preset.utterances.count, utterance.say)
            let placements = await processor.processTranscript(
                utterance.say,
                modelContext: modelContext,
                sendNotification: false
            )
            results.append(
                SpokenSortResult(
                    id: "\(preset.id)-\(utterance.id)",
                    say: utterance.say,
                    expectedLists: utterance.expectedLists,
                    actualLists: placements.map(\.listName),
                    actualTitles: placements.map(\.title),
                    kind: utterance.kind,
                    errorMessage: placements.isEmpty ? processor.lastError : nil
                )
            )
        }
        return results
    }
}
