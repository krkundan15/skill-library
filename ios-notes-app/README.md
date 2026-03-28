# iOS Notes App

A personal note-taking app for iOS that lets you capture thoughts with a single button press, then uses AI to organise, summarise, and extract action items — displayed across Day / Week / Month planning views.

## Features

- **Quick Capture** — floating action button (always visible) + home screen widget
- **Text & Voice** — type or dictate; voice notes are auto-transcribed via SFSpeechRecognizer
- **Auto date/time stamp** — every note is timestamped on creation
- **Personal / Work categories** — colour-coded (blue / orange)
- **AI summarisation & action extraction** — uses Claude API when online, Apple NaturalLanguage framework offline
- **Planning views** — Day timeline, 7-day Week strip, Month calendar grid
- **Action items** — extracted automatically, grouped by Today / Upcoming / Done with checkboxes

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9
- (Optional) Anthropic API key for Claude AI features

## Setup

### 1. Clone and open in Xcode

```bash
git clone <repo>
cd skill-library/ios-notes-app
open Package.swift   # Opens in Xcode
```

### 2. Configure targets in Xcode

Because WidgetKit extensions require app extension entitlements, you need to:

1. Create a new Xcode project (iOS App)
2. Add a Widget Extension target
3. Add the `NotesShared` SPM package as a dependency to both targets
4. Copy `Sources/NotesApp/` files into the app target
5. Copy `Sources/NotesWidget/` files into the widget target

See `docs/xcode-setup.md` for a step-by-step guide.

### 3. Add your Claude API key

1. Launch the app
2. Go to **Settings** tab
3. Tap **AI Settings** and enter your [Anthropic API key](https://console.anthropic.com/)
4. The key is stored securely in the iOS Keychain

The app works fully offline without an API key — it uses Apple's on-device NLP for summarisation and action extraction.

### 4. Permissions

Add these keys to your `Info.plist`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Used to transcribe your voice notes.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to record voice notes.</string>
```

## Project Structure

```
ios-notes-app/
├── Package.swift
├── Sources/
│   ├── NotesShared/        # Models + AI services (shared with widget)
│   ├── NotesApp/           # Main app views, utilities, services
│   └── NotesWidget/        # Home screen widget
└── Tests/
    └── NotesSharedTests/   # Unit tests
```

## AI Model

The app uses `claude-haiku-4-5` for fast, cost-effective summarisation and action extraction. The prompt requests a structured JSON response:

```json
{
  "summary": "One-sentence summary of the note",
  "actions": ["Action item 1", "Action item 2"]
}
```

## URL Scheme

The app registers the `notesapp://` URL scheme. The widget uses `notesapp://capture` to open the Quick Capture sheet directly.
