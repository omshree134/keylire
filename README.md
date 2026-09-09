# Keyva 🗝️
> **A local-first logbook that knows what time it is.**

Keyva is a fast, intelligent, private life logbook built with Flutter. It understands what you did, what you plan to do, and what you need to remember—without ever sending your private logs to the cloud.

---

## ✨ Features

- **🕒 3-Tense Architecture**:
  - `Done`: Real logs of what happened, placed chronologically along the day ribbon.
  - `Planned` (Ghosts): Tasks scheduled for a specific time or time-of-day window.
  - `List`: Items to do without a specific time yet; promote them to your day anytime.
- **🧠 Local-First AI & Smart Matcher**:
  - On-device vector embeddings and kNN anchor matching for your personal activity keys.
  - **Learning Mode**: Teaches Keyva your habits, suggests smart new keys, and lets you create custom keys with 1 tap.
- **🌅 Sleep-Aware & Time-Relevant Key Chips**:
  - Automatically learns when you usually sleep and wake.
  - Dynamically positions `Up` (morning) and `Bed` (night) and presents quick key chips tailored to the active time of day (e.g. coffee/breakfast in the morning, lunch in midday, dinner/reading at night).
- **📸 Smart Photo Understanding**:
  - On-device OCR and image understanding auto-tags and files photos into relevant activities.
- **📊 Patterns & Heatmaps**:
  - Visual streak tracking, 12-week frequency heatmaps, and quantity sparklines.
- **🔐 Encrypted Local Backups**:
  - Export and restore your complete database with pass-phrase encrypted single-file `.keyva` archives.
- **📱 Home Screen Widget**:
  - Android home screen widget with quick action triggers for voice, camera, and one-tap logging.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.22+ recommended)
- Dart SDK
- Android Studio / Xcode

### Setup & Run

```bash
# Clone the repository
git clone https://github.com/Zeren1347/Keyva.git
cd Keyva/keyva

# Install dependencies
flutter pub get

# Generate Drift database models
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Launch the app
flutter run
```

---

## 📂 Project Structure

```
Keyva/
├── keyva/
│   ├── lib/
│   │   ├── core/         # Parsing, time resolution, day logic
│   │   ├── data/         # Drift SQLite database, schema, migrations
│   │   ├── services/     # Capture, matching, embeddings, photo OCR, time vocab
│   │   ├── ui/           # Today screen, Lists, Patterns, Settings, Widgets
│   │   └── main.dart     # Application entry point
│   ├── test/             # Comprehensive unit & widget test suites
│   ├── android/          # Native Android configuration & Home widget
│   └── ios/              # Native iOS configuration
├── .gitignore
└── README.md
```

---

## 🔒 Privacy & Architecture

Keyva is strictly local-first:
- All database records (`daylog.sqlite`), embeddings, and OCR run locally on your device.
- No remote telemetry, no mandatory sign-up, no analytics tracking.
