# BetterReminders

Voice-powered reminders for iPhone. Press the Action Button, speak naturally, and BetterReminders transcribes your memo, summarizes it, and sorts it into the right list.

**Stack:** SwiftUI · SwiftData · App Intents · on-device Speech · OpenAI (`gpt-4o-mini`)

## Features

- **Action Button integration** — Toggle recording from the iPhone Action Button via App Intents
- **Voice capture** — Record reminders hands-free from the app or Action Button
- **On-device transcription** — Apple Speech framework keeps your voice private
- **Smart categorization** — OpenAI parses and assigns reminders to lists (Groceries, Work, etc.)
- **Smart lists** — Pre-seeded categories plus custom lists
- **Local storage** — SwiftData persistence, no system Reminders dependency

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
