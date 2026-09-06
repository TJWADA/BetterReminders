# BetterReminders

iOS reminder app that captures spoken tasks from the iPhone Action Button, transcribes them on-device with Apple Speech, and stores them locally in SwiftData. Audio transcripts are processed through the OpenAI API to extract key metadata — descriptions, due dates, and priority levels — and automatically categorize them into user-created lists.

**Stack:** Swift · SwiftUI · SwiftData · App Intents · on-device Speech · OpenAI (`gpt-4o-mini`)

## Features

- **Action Button capture** — Speak a task hands-free from the iPhone Action Button (App Intents)
- **On-device transcription** — Apple Speech keeps your voice private; audio never leaves the device for STT
- **Metadata extraction** — OpenAI pulls out descriptions, due dates, and priority levels from natural speech
- **Smart categorization** — Automatically sorts reminders into user-created list types (Groceries, Work, etc.)
- **Local storage** — SwiftData persistence with no dependency on Apple’s system Reminders app
- **Smart lists** — Pre-seeded categories plus custom lists you define

## Engineering highlights

- App Group container shares recording session state between the intent and the main app
- API key stored in Keychain, never in UserDefaults or source
- List classification uses each list’s description, sample titles, and past correction notes
- Unit tests cover parsing, filters, notifications, and job cleanup

## Requirements

- Xcode 16+
- iOS 18.0+
- iPhone 15 Pro or later for Action Button hardware (in-app recording works on all iPhones)
- OpenAI API key (enter in Settings)

## Getting Started

1. Open `BetterReminders.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities for all targets
3. Build and run on a physical device (microphone and Action Button require hardware)
4. Go to **Settings** and add your OpenAI API key
5. Grant Microphone and Speech Recognition permissions
6. Follow **Settings → Set Up Action Button** to bind the shortcut

## Action Button Setup

1. Open iPhone **Settings → Action Button**
2. Choose **Shortcut**
3. Select **BetterReminders → Toggle Recording**
4. Press Action Button to start/stop recording

## Architecture

```
Action Button → ToggleRecordingIntent → AudioRecordingService
Stop → SpeechService (on-device STT) → ReminderParserService (OpenAI)
     → ReminderProcessingService → SwiftData
```

## Project Structure

- `BetterReminders/` — Main app (SwiftUI, SwiftData, App Intents)
- `BetterRemindersCore/` — Shared framework (recording, session state, App Intents)
- `BetterRemindersTests/` — Unit tests
