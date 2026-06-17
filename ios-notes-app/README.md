# iOS Notes App

A personal note-taking app for iOS that lets you capture thoughts with a single button press, then uses AI to organise, summarise, and extract action items — displayed across Day / Week / Month planning views.

## Features

- **Quick Capture** — floating action button (always visible) + home screen widget
- **Meeting Mode** — record long-form meetings with a live, continuously-updating transcript, then get an AI overview, key discussion points, decisions, and action items
- **Text & Voice** — type or dictate; voice notes are auto-transcribed via SFSpeechRecognizer
- **Auto date/time stamp** — every note is timestamped on creation
- **Personal / Work categories** — colour-coded (blue / orange)
- **AI summarisation & action extraction** — choose Claude or DeepSeek when online, with automatic fallback to Apple's on-device NaturalLanguage framework offline
- **Planning views** — Day timeline, 7-day Week strip, Month calendar grid
- **Action items** — extracted automatically, grouped by Today / Upcoming / Done with checkboxes

## Requirements

- iPhone 12 or later, running iOS 17+ (the app uses no hardware features beyond what iPhone 12 supports — SwiftData and the UI are the only iOS 17 requirements)
- Xcode 15+
- Swift 5.9
- (Optional) Anthropic API key for Claude, and/or a DeepSeek API key — either, both, or neither (on-device only)

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

### 3. Configure an AI provider (optional)

1. Launch the app and go to the **Settings** tab
2. Under **AI Settings**, pick a provider: **Claude**, **DeepSeek**, or **On-device only**
3. For Claude, enter your [Anthropic API key](https://console.anthropic.com/); for DeepSeek, enter your [DeepSeek API key](https://platform.deepseek.com/)
4. Tap **Save Key** — keys are stored securely in the iOS Keychain, never in UserDefaults

The app works fully offline without any API key — it uses Apple's on-device NLP for summarisation and action extraction, and automatically falls back to it whenever the network is unavailable or the selected provider's request fails, regardless of which provider is selected.

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

## Meeting Mode

Tap the **+** button and choose **New Meeting** to start a recording. While recording:

- Audio is written continuously to a single `.m4a` file in the app's Documents directory — recording never stops or restarts, even while transcription is cycling in the background.
- A live transcript streams in as you speak. `SFSpeechRecognizer` caps each recognition request at roughly 60 seconds, so `MeetingRecorderService` transparently restarts the recognition request every 50 seconds and stitches the results together — the audio tap and the visible transcript never have a gap.
- You can pause/resume at any time; pausing stops the audio engine and finalises the in-flight transcript chunk, resume starts a fresh chunk.

When you tap **Stop & Summarise**, the full transcript is saved to the note and handed to the configured AI provider (or the on-device fallback), which returns:

- A 2–3 sentence **overview**
- **Key points** discussed
- **Decisions** made
- **Action items** to follow up on

## AI Models

| Provider | Model | Notes |
|---|---|---|
| Claude | `claude-haiku-4-5` | Fast, cost-effective |
| DeepSeek | `deepseek-chat` | OpenAI-compatible API |
| On-device | Apple `NaturalLanguage` | No network or API key required |

Both online providers are called through a shared `AIProvider` protocol and requested to return structured JSON. For quick notes:

```json
{
  "summary": "One-sentence summary of the note",
  "actions": ["Action item 1", "Action item 2"]
}
```

For meetings:

```json
{
  "summary": "2-3 sentence overview of the meeting",
  "keyPoints": ["Key discussion point"],
  "decisions": ["Decision made"],
  "actions": ["Concrete follow-up action"]
}
```

If a request to the selected online provider fails for any reason (offline, missing/invalid key, API error), the app transparently falls back to the on-device NLP service so notes are never left unprocessed.

## URL Scheme

The app registers the `notesapp://` URL scheme. The widget uses `notesapp://capture` to open the Quick Capture sheet directly.
