# Keyva v2 — the three-tense rebuild

This replaces `lib/`, `test/`, and `pubspec.yaml`. Keep your `android/`, `ios/`,
and the Kotlin widget providers; the widget URIs are listed at the end.

## What's in this drop

**Schema v2 (auto-migrates from v1).** `events` gains `status` (done / planned /
pending / skipped), `duration_min`, `quantity`, `unit`, `note`, `list_item_id`.
`keys` gains `usual_minute_override`, `notes_affinity`, `notes_added`,
`notes_ignored`. New tables `list_items` and `corrections`. Old `future_entries`
rows become planned events at their hint time.

**EntryParser** (`lib/core/parse/entry_parser.dart`). Deterministic, no model.
Reads tense, day words (incl. *kal*, weekdays), clock times (12h/24h/*baje*),
named windows (*this evening*, *tonight*, *shaam ko*, *before bed*), quantities
(km/pages/kcal/₹/steps/…), durations, and a note signal. Distinguishes
*"evening walk 30 min"* (a report) from *"laundry this evening"* (a plan), and
knows that *"dinner at 8"* said at 14:32 is a plan.

**Corpus** (`test/corpus/phrases.jsonl`, 78 lines) + **scorecard**
(`test/corpus_test.dart`). Run `flutter test test/corpus_test.dart`. First run
writes `baseline.json`; from then on any per-field regression fails the test.
`UPDATE_BASELINE=1 flutter test …` after an intentional improvement.
Settings → tap the version line → *Export corrections* dumps every user
correction as jsonl to paste into the corpus.

**TimeVocabService.** "Morning" for *gym* = the median of your own gym logs
between 05:00–11:30 over 60 days; falls back to all keys, then to a default.
No table, no training step — it's a query.

**CaptureService v2.** parse → match → resolve → write. Bed/Up fixed keys.
`completePlanned`, `skipPlanned`, `moveToToday`, list item add/tick/promote,
note affinity learning (+2 → on, 5 ignores → off), corrections recorded on
every override.

**PhotoUnderstandingService.** ML Kit labels + OCR on every device; kind
detection (food / screenshot / gym / study / place); kcal lexicon; a
`PlatformCaptioner` seam for AICore / Apple on-device captions. No cloud.

**UI.** New palette (ink on bone; see `daylog_theme.dart`). Today: date +
ring + live arithmetic line, morning-review strip, ribbon with the now-fold
and ghost stitches on a dotted rail, quantities in mono, expandable notes.
Capture bar: Bed / Up fixed left, due-now chips with a hollow dot, usual-now
chips with a hue dot. Undo chip: *Filed under gym — Change · Add note*.
Lists tab, Patterns (tap the usual time to set it; planned-vs-done; quantity
sparkline), Settings, Onboarding (3 screens).

## Build

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test test/corpus_test.dart          # writes baseline.json on first run
flutter analyze                             # expect a few nits, no errors
flutter run
```

I can't compile here, so expect `flutter analyze` to flag small things
(unused imports, a nullable I missed). Nothing structural.

## ONNX model (do this once, ~10 min)

```
pip install optimum[onnxruntime] onnx onnxruntime
optimum-cli export onnx --model sentence-transformers/all-MiniLM-L6-v2 minilm/
python - <<'EOF'
from onnxruntime.quantization import quantize_dynamic, QuantType
quantize_dynamic("minilm/model.onnx", "minilm-l6-v2-int8.onnx", weight_type=QuantType.QInt8)
EOF
cp minilm-l6-v2-int8.onnx assets/models/
cp minilm/vocab.txt assets/models/
```

Until the file is there the app logs *"ONNX model missing"* and uses the
hashing embedder — fine for UI work, useless for matching.

## Widget URIs (Kotlin side)

```
keyva://capture/chip?id=<keyId>&name=<name>
keyva://capture/bed
keyva://capture/up
keyva://capture/camera
keyva://capture/mic
keyva://capture/text
keyva://lists
```

## Open (next drop)

- Drag a stitch along the rail to re-time it (edit sheet covers it today).
- Day ring tap → day visualization (dropped; old screen used the v1 view).
- Usual-time notifications: toggle exists, scheduler doesn't (Android first).
- Ghosts from recurrence proposals (engine still only proposes).
- Run ONNX embed in an isolate — watch for jank on the first match after launch.
- Week review, encrypted auto-backup, multiple named lists — deferred as agreed.
