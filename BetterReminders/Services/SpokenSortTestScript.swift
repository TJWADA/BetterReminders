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

struct SpokenSortResult: Identifiable {
    let id: Int
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
    static let lists: [SpokenSortListSpec] = [
        SpokenSortListSpec(
            name: "General",
            icon: "tray.fill",
            colorHex: "8E8E93",
            description: "Catch-all for reminders that do not clearly fit another list."
        ),
        SpokenSortListSpec(
            name: "Groceries",
            icon: "cart.fill",
            colorHex: "34C759",
            description: "Food and household shopping items to buy at a store."
        ),
        SpokenSortListSpec(
            name: "Workout",
            icon: "figure.run",
            colorHex: "5AC8FA",
            description: "Exercise, gym sessions, training, stretches, and sports. Not medical care."
        ),
        SpokenSortListSpec(
            name: "Health",
            icon: "heart.fill",
            colorHex: "FF3B30",
            description: "Medical appointments, medications, symptoms, and wellness that is not a workout."
        ),
        SpokenSortListSpec(
            name: "Ideas",
            icon: "lightbulb.fill",
            colorHex: "FFD60A",
            description: "Brainstorms, things to explore later, and notes that are not chores yet."
        ),
        SpokenSortListSpec(
            name: "Work",
            icon: "briefcase.fill",
            colorHex: "007AFF",
            description: "Job tasks, meetings, emails, and professional follow-ups."
        ),
        SpokenSortListSpec(
            name: "Errands",
            icon: "car.fill",
            colorHex: "FF9500",
            description: "Out-and-about tasks like pickups, returns, post office, and dry cleaning. Not grocery shopping."
        ),
    ]

    static let utterances: [SpokenSortUtterance] = [
        SpokenSortUtterance(id: 1, say: "Remind me to buy milk", expectedLists: ["Groceries"], kind: .clear),
        SpokenSortUtterance(id: 2, say: "Add bananas to the grocery list", expectedLists: ["Groceries"], kind: .clear),
        SpokenSortUtterance(id: 3, say: "We're out of oat milk and paper towels", expectedLists: ["Groceries"], kind: .clear),
        SpokenSortUtterance(id: 4, say: "Get chicken and rice for meal prep this week", expectedLists: ["Groceries"], kind: .clear),
        SpokenSortUtterance(id: 5, say: "Pick up a rotisserie chicken on the way home", expectedLists: ["Groceries"], kind: .borderline),
        SpokenSortUtterance(id: 6, say: "I need to do legs tomorrow", expectedLists: ["Workout"], kind: .clear),
        SpokenSortUtterance(id: 7, say: "Remind me to stretch after work", expectedLists: ["Workout"], kind: .clear),
        SpokenSortUtterance(id: 8, say: "Book a spin class for Thursday", expectedLists: ["Workout"], kind: .clear),
        SpokenSortUtterance(id: 9, say: "Don't forget to bring my gym shoes", expectedLists: ["Workout"], kind: .clear),
        SpokenSortUtterance(id: 10, say: "Do a twenty minute run in the morning", expectedLists: ["Workout"], kind: .clear),
        SpokenSortUtterance(id: 11, say: "Schedule a dentist appointment", expectedLists: ["Health"], kind: .clear),
        SpokenSortUtterance(id: 12, say: "Take my vitamins in the morning", expectedLists: ["Health"], kind: .clear),
        SpokenSortUtterance(id: 13, say: "Refill my prescription", expectedLists: ["Health"], kind: .borderline),
        SpokenSortUtterance(id: 14, say: "Call the doctor about this cough", expectedLists: ["Health"], kind: .clear),
        SpokenSortUtterance(id: 15, say: "Drink more water today", expectedLists: ["Health"], kind: .borderline),
        SpokenSortUtterance(id: 16, say: "I should try that new sourdough recipe sometime", expectedLists: ["Ideas"], kind: .clear),
        SpokenSortUtterance(id: 17, say: "Maybe start a newsletter", expectedLists: ["Ideas"], kind: .clear),
        SpokenSortUtterance(id: 18, say: "Look into that standing desk I saw", expectedLists: ["Ideas"], kind: .clear),
        SpokenSortUtterance(id: 19, say: "Idea for an app: a habit tracker that talks to you", expectedLists: ["Ideas"], kind: .clear),
        SpokenSortUtterance(id: 20, say: "We should do a weekend trip to Tahoe", expectedLists: ["Ideas"], kind: .clear),
        SpokenSortUtterance(id: 21, say: "Send the Q3 recap to Sarah by Friday", expectedLists: ["Work"], kind: .clear),
        SpokenSortUtterance(id: 22, say: "Follow up with the recruiter", expectedLists: ["Work"], kind: .clear),
        SpokenSortUtterance(id: 23, say: "Prep for the standup tomorrow", expectedLists: ["Work"], kind: .clear),
        SpokenSortUtterance(id: 24, say: "Don't forget the three pm client call", expectedLists: ["Work"], kind: .clear),
        SpokenSortUtterance(id: 25, say: "Drop off the dry cleaning", expectedLists: ["Errands"], kind: .clear),
        SpokenSortUtterance(id: 26, say: "Return the Amazon package", expectedLists: ["Errands"], kind: .clear),
        SpokenSortUtterance(id: 27, say: "Pick up the kids from soccer at five", expectedLists: ["Errands"], kind: .clear),
        SpokenSortUtterance(id: 28, say: "Get the car inspected this week", expectedLists: ["Errands"], kind: .clear),
        SpokenSortUtterance(id: 29, say: "Remind me to text Mom", expectedLists: ["General"], kind: .catchAll),
        SpokenSortUtterance(id: 30, say: "Charge my headphones", expectedLists: ["General"], kind: .catchAll),
        SpokenSortUtterance(id: 31, say: "Water the plants", expectedLists: ["General"], kind: .catchAll),
        SpokenSortUtterance(id: 32, say: "Take the trash out tonight", expectedLists: ["General"], kind: .catchAll),
        SpokenSortUtterance(id: 33, say: "Buy protein powder", expectedLists: ["Groceries"], kind: .borderline),
        SpokenSortUtterance(id: 34, say: "Buy new running shoes", expectedLists: ["Errands"], kind: .borderline),
        SpokenSortUtterance(id: 35, say: "Get ibuprofen at the store", expectedLists: ["Groceries"], kind: .borderline),
        SpokenSortUtterance(id: 36, say: "Meal prep for the week", expectedLists: ["Workout"], kind: .borderline),
        SpokenSortUtterance(id: 37, say: "Try that new abs routine I saw on Instagram", expectedLists: ["Ideas"], kind: .borderline),
        SpokenSortUtterance(id: 38, say: "Go for a walk to clear my head", expectedLists: ["Workout"], kind: .borderline),
        SpokenSortUtterance(id: 39, say: "Research better sleep habits", expectedLists: ["Ideas"], kind: .borderline),
        SpokenSortUtterance(id: 40, say: "The wifi password is on the fridge", expectedLists: ["General"], kind: .catchAll),
        SpokenSortUtterance(
            id: 41,
            say: "Buy eggs and also email John about the contract",
            expectedLists: ["Groceries", "Work"],
            kind: .split
        ),
        SpokenSortUtterance(
            id: 42,
            say: "Pick up the dry cleaning and get milk",
            expectedLists: ["Errands", "Groceries"],
            kind: .split
        ),
    ]

    static func score(expected: [String], actual: [String]) -> Bool {
        let expectedSet = Set(expected.map { $0.lowercased() })
        let actualSet = Set(actual.map { $0.lowercased() })
        return !expectedSet.isEmpty && expectedSet == actualSet
    }

    @MainActor
    static func prepareLists(modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<ReminderList>())) ?? []
        let fixtureNames = Set(lists.map { $0.name.lowercased() })

        for (index, spec) in lists.enumerated() {
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
        modelContext: ModelContext,
        processor: ReminderProcessingService,
        onProgress: (Int, Int, String) -> Void
    ) async -> [SpokenSortResult] {
        prepareLists(modelContext: modelContext)

        var results: [SpokenSortResult] = []
        for (index, utterance) in utterances.enumerated() {
            onProgress(index + 1, utterances.count, utterance.say)
            let placements = await processor.processTranscript(
                utterance.say,
                modelContext: modelContext,
                sendNotification: false
            )
            results.append(
                SpokenSortResult(
                    id: utterance.id,
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
