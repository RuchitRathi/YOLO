# YOLO! — Stop Thinking. Start Living.

A Flutter app for spontaneous decisions, personalized mini missions, timed mission runs, memories, and XP progression. It uses an original comic pop-art palette and keeps gameplay available offline.

## Requirements

- Flutter stable 3.38.1+ with Dart 3.10+
- Android Studio or Android SDK for device and APK builds
- Optional Supabase project for existing profile and progress sync
- Squad YOLO local demo (no backend required)

## Run

```sh
flutter pub get
flutter run
```

The app opens with an animated YOLO splash, then moves to the home dashboard. Set a name through Preferences. Chaos Mode filters out activities that exceed the selected time/budget/environment and then ranks compatible results with the configured weighted score. A random choice among up to three top matches adds controlled variety. Decide for Me supports 2–12 options and uses `Random.secure()` by default.

Explore Missions generates personalized missions with Google's hosted `gemini-3.5-flash-lite` model. It uses the saved vibe, local date/time, recent mission history, device location from Geolocator, and current weather from Open-Meteo. Location is requested only after tapping the generator; coordinates are sent to Open-Meteo for a forecast and rounded to neighborhood-level precision for Gemini. Open-Meteo does not require an API key. Its free endpoint is for non-commercial use and requires CC BY 4.0 attribution; the app credits Open-Meteo in the mission screen. For commercial use, use an appropriate paid weather plan or another licensed weather source. If location/weather is unavailable, generation continues without a forecast. Gemini streams mission cards as each one is ready, and each generated mission includes a short explanation of why it fits. If the key or network is unavailable, the app instantly shows three on-device suggestions based on the selected vibe and recent history. A 30-second sample run demonstrates the full timer, completion, XP, and share-card flow. Configure only `GEMINI_API_KEY` in `supabase.config.json` (or pass it with `--dart-define`). This direct API-key setup is for local prototyping; for a public release, route Gemini requests through Firebase AI Logic or a backend so a reusable Gemini key is not embedded in the app.

## Shinchan local companion

The home screen's **Ask Shinchan** opens a streaming character chat powered by the local Ollama API. The browser demo connects to `http://127.0.0.1:11434`; the Android emulator defaults to `http://10.0.2.2:11434`. Open Ollama and install a model such as `qwen2.5:1.5b-instruct`. The chat discovers installed models, lets you choose one, and stores up to 30 recent messages on device. It does not send the chat to Gemini or another cloud API. Use the settings button in the chat to change the Ollama endpoint for a physical Android device on the same network.

Mission details open a mission-specific “near me” search directly in the device's maps app. YOLO does not wait for a GPS fix, public place-search service, or local AI ranking; Maps uses the device's own location and provides live place results and directions. No map API key is needed.


Screens live under `lib/features/`, app setup and route transitions under `lib/app/`, and shared comic components under `lib/shared/widgets/`. Content is width-constrained on larger displays, while onboarding scrolls on short screens.

Progress, username, XP, completion count, and memories are stored on device with SharedPreferences. When Supabase is configured, profile progress and mission history sync to the signed-in anonymous user and are merged back on startup. No API keys are required for local demo mode.

## Supabase setup (optional progress sync)

1. Enable anonymous sign-ins in Supabase Authentication.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. Run `supabase/seed.sql` to add sample mission rows and achievements.
4. Copy `supabase.config.example.json` to `supabase.config.json`, then add your project URL and anon/publishable key. Never put a service-role key in the app. The real config file is git-ignored.
5. Start with the config file:

```sh
flutter run --dart-define-from-file=supabase.config.json
```

Add `"GEMINI_API_KEY": "your-gemini-key"` to that same JSON file for personalized missions. Weather does not need a key. For a release build, avoid shipping a reusable Gemini key in a client app; put the request behind a server endpoint or use Firebase AI Logic.

The SQL trigger creates each new user's profile and preferences. Local progress remains the source of truth while offline; profile XP, streak, completion count, username, and mission history sync when the connection is available.

## Crew Huddle

Crew Huddle is a same-device group vote for 2–6 people. Each person privately enters a name, vibe, time limit, budget, and preferred setting before passing the phone to the next player. Once everyone votes, YOLO reveals a mission that fits the group's tightest time and budget limits. Names and votes stay in screen memory and reset when you leave; there are no simulated players, room codes, accounts, or network connection.

Starting a mission opens a timed run with the instructions, pause/resume, and an early-finish action. Completing it awards XP and opens a share-card preview. You can optionally add a gallery photo, then export the rendered card to the operating system share menu. Instagram Stories, WhatsApp and TikTok appear when supported/installed by the device; the app hands off through the standard share sheet rather than publishing directly.

The Shinchan image is included as a transparent PNG in `assets/images/shinchan.png`. The home hero gives him an idle bounce and a tap-triggered wiggle.

## Tests and analysis

```sh
flutter analyze
flutter test
```

Tests cover decision bounds, random selection, hard filters, recommendation relevance, the home and mission completion journey, XP updates, and phone/wide layout breakpoints. XP is awarded on mission completion; levels advance every 100 XP.

## Build Android APK

```sh
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`.
