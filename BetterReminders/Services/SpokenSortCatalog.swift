import Foundation

enum SpokenSortCatalog {
    static let all: [SpokenSortPreset] = [
        fitnessSplit,
        firstRun,
        student,
        household,
        minimal,
    ]

    static func preset(id: String) -> SpokenSortPreset {
        all.first { $0.id == id } ?? fitnessSplit
    }

    static let fitnessSplit = SpokenSortPreset(
        id: "fitnessSplit",
        name: "Fitness split",
        summary: "Workout vs Health vs Groceries. The original full script.",
        lists: [
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
        ],
        utterances: [
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
    )

    static let firstRun = SpokenSortPreset(
        id: "firstRun",
        name: "First-run defaults",
        summary: "Fresh install lists. Health includes exercise; Personal catches home tasks. No Workout list.",
        lists: ListSeeder.defaultLists.map {
            SpokenSortListSpec(
                name: $0.name,
                icon: $0.icon,
                colorHex: $0.colorHex,
                description: $0.description
            )
        },
        utterances: [
            SpokenSortUtterance(id: 1, say: "Remind me to buy milk", expectedLists: ["Groceries"], kind: .clear),
            SpokenSortUtterance(id: 2, say: "I need to do legs tomorrow", expectedLists: ["Health"], kind: .clear),
            SpokenSortUtterance(id: 3, say: "Remind me to text Mom", expectedLists: ["Personal"], kind: .clear),
            SpokenSortUtterance(id: 4, say: "Water the plants", expectedLists: ["Personal"], kind: .clear),
            SpokenSortUtterance(id: 5, say: "Send the Q3 recap to Sarah by Friday", expectedLists: ["Work"], kind: .clear),
            SpokenSortUtterance(id: 6, say: "Drop off the dry cleaning", expectedLists: ["Errands"], kind: .clear),
            SpokenSortUtterance(id: 7, say: "Maybe start a newsletter", expectedLists: ["Ideas"], kind: .clear),
            SpokenSortUtterance(id: 8, say: "Schedule a dentist appointment", expectedLists: ["Health"], kind: .clear),
            SpokenSortUtterance(id: 9, say: "Remind me to stretch after work", expectedLists: ["Health"], kind: .borderline),
            SpokenSortUtterance(id: 10, say: "Buy protein powder", expectedLists: ["Groceries"], kind: .borderline),
            SpokenSortUtterance(id: 11, say: "Book a spin class for Thursday", expectedLists: ["Health"], kind: .borderline),
            SpokenSortUtterance(id: 12, say: "Charge my headphones", expectedLists: ["Personal"], kind: .catchAll),
            SpokenSortUtterance(id: 13, say: "Take the trash out tonight", expectedLists: ["Personal"], kind: .catchAll),
            SpokenSortUtterance(
                id: 14,
                say: "Buy eggs and also email John about the contract",
                expectedLists: ["Groceries", "Work"],
                kind: .split
            ),
            SpokenSortUtterance(
                id: 15,
                say: "Pick up the dry cleaning and get milk",
                expectedLists: ["Errands", "Groceries"],
                kind: .split
            ),
        ]
    )

    static let student = SpokenSortPreset(
        id: "student",
        name: "Student",
        summary: "Course lists with empty descriptions. Only the name tells the parser where homework goes.",
        lists: [
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
                name: "CSE 121",
                icon: "book.fill",
                colorHex: "5856D6",
                description: ""
            ),
            SpokenSortListSpec(
                name: "CSE 332",
                icon: "function",
                colorHex: "AF52DE",
                description: ""
            ),
            SpokenSortListSpec(
                name: "Clubs",
                icon: "person.3.fill",
                colorHex: "FF9500",
                description: "Student clubs, social events, and extracurriculars."
            ),
        ],
        utterances: [
            SpokenSortUtterance(id: 1, say: "Finish the CSE 121 homework", expectedLists: ["CSE 121"], kind: .clear),
            SpokenSortUtterance(id: 2, say: "Review heaps for 332", expectedLists: ["CSE 332"], kind: .clear),
            SpokenSortUtterance(id: 3, say: "Buy ramen and oat milk", expectedLists: ["Groceries"], kind: .clear),
            SpokenSortUtterance(id: 4, say: "Read chapter 5 for 121", expectedLists: ["CSE 121"], kind: .clear),
            SpokenSortUtterance(id: 5, say: "Go to office hours for 332", expectedLists: ["CSE 332"], kind: .clear),
            SpokenSortUtterance(id: 6, say: "Sign up for the hiking club trip", expectedLists: ["Clubs"], kind: .clear),
            SpokenSortUtterance(id: 7, say: "Email the TA about the midterm", expectedLists: ["CSE 121"], kind: .borderline),
            SpokenSortUtterance(id: 8, say: "Print the 121 lab writeup", expectedLists: ["CSE 121"], kind: .borderline),
            SpokenSortUtterance(id: 9, say: "RSVP for the club bake sale", expectedLists: ["Clubs"], kind: .clear),
            SpokenSortUtterance(id: 10, say: "Remind me to text Mom", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 11, say: "Charge my laptop", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 12, say: "Maybe apply to internships", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(
                id: 13,
                say: "Buy ramen and finish the 121 homework",
                expectedLists: ["Groceries", "CSE 121"],
                kind: .split
            ),
            SpokenSortUtterance(
                id: 14,
                say: "Get more instant coffee and review heaps",
                expectedLists: ["Groceries", "CSE 332"],
                kind: .split
            ),
        ]
    )

    static let household = SpokenSortPreset(
        id: "household",
        name: "Household",
        summary: "Kids vs Home vs Errands vs Groceries. Family tasks should not land in Errands.",
        lists: [
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
                name: "Kids",
                icon: "figure.and.child.holdinghands",
                colorHex: "FF2D55",
                description: "Childcare, school, activities, and things for the kids."
            ),
            SpokenSortListSpec(
                name: "Home",
                icon: "house.fill",
                colorHex: "64D2FF",
                description: "Household chores and repairs done at home, not errands in town."
            ),
            SpokenSortListSpec(
                name: "Errands",
                icon: "car.fill",
                colorHex: "FF9500",
                description: "Out-and-about tasks like pickups, returns, post office, and dry cleaning. Not grocery shopping or kid pickups."
            ),
        ],
        utterances: [
            SpokenSortUtterance(id: 1, say: "Pick up the kids from soccer at five", expectedLists: ["Kids"], kind: .clear),
            SpokenSortUtterance(id: 2, say: "Pack lunches for tomorrow", expectedLists: ["Kids"], kind: .clear),
            SpokenSortUtterance(id: 3, say: "Fix the leaky faucet", expectedLists: ["Home"], kind: .clear),
            SpokenSortUtterance(id: 4, say: "Take the trash out tonight", expectedLists: ["Home"], kind: .clear),
            SpokenSortUtterance(id: 5, say: "Return the Amazon package", expectedLists: ["Errands"], kind: .clear),
            SpokenSortUtterance(id: 6, say: "Get milk and diapers", expectedLists: ["Groceries"], kind: .clear),
            SpokenSortUtterance(id: 7, say: "Sign the school permission slip", expectedLists: ["Kids"], kind: .clear),
            SpokenSortUtterance(id: 8, say: "Drop off the dry cleaning", expectedLists: ["Errands"], kind: .clear),
            SpokenSortUtterance(id: 9, say: "Replace the furnace filter", expectedLists: ["Home"], kind: .clear),
            SpokenSortUtterance(id: 10, say: "Text the babysitter", expectedLists: ["Kids"], kind: .borderline),
            SpokenSortUtterance(id: 11, say: "Pick up a birthday gift for Noah's friend", expectedLists: ["Kids"], kind: .borderline),
            SpokenSortUtterance(id: 12, say: "Charge my headphones", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(
                id: 13,
                say: "Get milk and pick up Noah from practice",
                expectedLists: ["Groceries", "Kids"],
                kind: .split
            ),
            SpokenSortUtterance(
                id: 14,
                say: "Return the package and get milk",
                expectedLists: ["Errands", "Groceries"],
                kind: .split
            ),
        ]
    )

    static let minimal = SpokenSortPreset(
        id: "minimal",
        name: "Minimal catch-all",
        summary: "Only General, Groceries, and Workout. Work, health, ideas, and errands should fall through to General.",
        lists: [
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
        ],
        utterances: [
            SpokenSortUtterance(id: 1, say: "Remind me to buy milk", expectedLists: ["Groceries"], kind: .clear),
            SpokenSortUtterance(id: 2, say: "I need to do legs tomorrow", expectedLists: ["Workout"], kind: .clear),
            SpokenSortUtterance(id: 3, say: "Book a spin class for Thursday", expectedLists: ["Workout"], kind: .clear),
            SpokenSortUtterance(id: 4, say: "Buy protein powder", expectedLists: ["Groceries"], kind: .borderline),
            SpokenSortUtterance(id: 5, say: "Get ibuprofen at the store", expectedLists: ["Groceries"], kind: .borderline),
            SpokenSortUtterance(id: 6, say: "Send the Q3 recap to Sarah by Friday", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 7, say: "Schedule a dentist appointment", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 8, say: "Maybe start a newsletter", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 9, say: "Drop off the dry cleaning", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 10, say: "Remind me to text Mom", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 11, say: "Water the plants", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(id: 12, say: "Research better sleep habits", expectedLists: ["General"], kind: .catchAll),
            SpokenSortUtterance(
                id: 13,
                say: "Buy eggs and also email John about the contract",
                expectedLists: ["Groceries", "General"],
                kind: .split
            ),
            SpokenSortUtterance(
                id: 14,
                say: "Do a twenty minute run and pick up milk",
                expectedLists: ["Workout", "Groceries"],
                kind: .split
            ),
        ]
    )
}
