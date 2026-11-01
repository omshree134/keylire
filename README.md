# Keylire

Keylire is a local-first, time-aware personal logbook and life tracker built with Flutter. It provides a chronological timeline interface designed around a three-tense model (Done, Planned, and List), on-device embedding matching, adaptive routine learning, and complete privacy.

---

## Core Architecture & Concepts

### 1. Three-Tense Model
- **Done**: Past activities that have already taken place. Placed chronologically along the timeline ribbon with timestamps, durations, numerical quantities, and notes.
- **Planned (Ghosts)**: Future activities planned for a specific time or time-of-day window (e.g. morning, after work, evening). Displayed with an open ring indicator on the timeline. Tapping a ghost confirms completion.
- **List Items**: Intentions and tasks without a specific scheduled time. Kept organized in dedicated sections and promotable to the active day ribbon at any point.

### 2. Time-Ribbon Timeline
- Continuous vertical chronological ribbon organizing the current day's events.
- An animated "Now" fold indicator visually separates completed past events from pending planned ghosts.
- Dynamic 24-hour day boundary resolution accounting for late-night logs and configurable day cutoff hours.

### 3. On-Device Machine Learning & Adaptive Learning Mode
- **Vector Embeddings & kNN Matching**: Custom activity keys are matched on-device using local text embeddings and cosine similarity against nearest-neighbor anchor examples.
- **Learning Mode**: Allows users to actively train the system on their personal vocabulary. Suggests intelligent key names extracted from natural descriptions, provides one-tap key creation, and records user confirmations and corrections locally.
- **Time-of-Day Key Relevance**: Quick-capture key chips are scored and sorted based on the current hour of the day and historical median times for each activity.
- **Learned Sleep & Wake Schedule**: Learns typical wake and sleep routines, automatically prioritizing the "Up" action in the morning (until logged) and "Bed" in the late evening/night.

### 4. Smart Multimodal Capture
- **Natural Language Parsing**: Extracts tense, explicit clock times, relative delays (e.g. "in 30 mins"), time windows ("tonight", "this morning"), quantities, units (e.g. km, kcal, pages, reps), durations, and note signals.
- **Speech-to-Text**: Voice logging with instant on-device recognition.
- **On-Device Photo Understanding**: Optical character recognition (OCR) and scene extraction for photos, automatically assigning relevant activity keys and descriptions without cloud processing.

### 5. Privacy and Local-First Storage
- Backed by an on-device SQLite database via Drift.
- Zero mandatory cloud sync, no accounts, and no analytics or telemetry tracking.
- Passphrase-encrypted backup and restore generating portable `.keylire` archives.

### 6. Patterns & Analytics
- 12-week frequency heatmaps per key.
- Streak counters and planned-vs-done completion metrics.
- Quantitative series tracking with sparkline graphs (e.g. daily distance, repetitions, calories).

---

## Technical Stack

- **Framework**: Flutter (Dart 3+)
- **Local Database**: Drift (SQLite) with WAL mode enabled
- **State Management**: Scoped service architecture and ChangeNotifier controllers
- **Embeddings**: On-device vector embeddings with kNN similarity scoring
- **Platform Features**: HomeWidget integration for native Android and iOS widgets

---

## Getting Started

### Prerequisites
- Flutter SDK (version 3.22 or higher)
- Android SDK / Xcode

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/omshree134/keylire.git
   cd keylire
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

2b. Download the embedding model (required — without it key matching is keyword-only):
   ```bash
   ./scripts/fetch_model.sh
   ```

3. Generate database code:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run tests:
   ```bash
   flutter test
   ```

5. Run the application:
   ```bash
   flutter run
   ```

---

## Repository Structure

```
keylire/
├── lib/
│   ├── core/         # Time resolution, day boundary logic, natural language parsing
│   ├── data/         # Drift SQLite schema, migrations, and database access
│   ├── services/     # Capture orchestration, matching, embeddings, photo OCR, time vocab
│   ├── ui/           # Today screen, Lists, Patterns, Settings, Widgets, Design System
│   └── main.dart     # Application initialization
├── test/             # Unit and widget test suites
├── android/          # Native Android configuration and Home Widget provider
└── ios/              # Native iOS configuration
```
