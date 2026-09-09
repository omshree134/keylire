import 'dart:typed_data';

import '../../data/db/database.dart';
import '../embeddings/embedding_service.dart';
import '../settings/settings_service.dart';

enum MatchDecision { autoAssign, picker, newKey }

class KeyScore {
  KeyScore(this.keyId, this.keyName, this.score);
  final int keyId;
  final String keyName;
  final double score;
}

class MatchResult {
  MatchResult(this.decision, this.top, this.inputVector);
  final MatchDecision decision;
  final List<KeyScore> top; // best-first, max 3
  final Float32List inputVector; // reuse when persisting the example
}

/// kNN matcher over key_examples (NOT centroids).
///
/// At personal scale (<100 keys, <2000 examples) brute-force cosine against
/// every stored example is milliseconds on-device, more accurate than a
/// drifting mean, and self-correcting: every confirmation adds a
/// nearest-neighbour anchor. Score per key = max similarity over its examples.
///
/// Thresholds (settings-backed):
///   >= auto_assign_threshold (0.85)  -> auto-assign + visible undo chip
///   >= picker_threshold      (0.60)  -> top-3 picker
///   below                            -> picker with "new key" pre-highlighted
class KeyMatcher {
  KeyMatcher(this.db, this.embedder, this.settings);

  final AppDatabase db;
  final EmbeddingService embedder;
  final SettingsService settings;

  List<_Anchor>? _cache;
  Map<int, String> _keyNames = {};

  Future<void> warmUp() async {
    final examples = await db.allExamples();
    final keys = await db.activeKeys();
    _keyNames = {for (final k in keys) k.id: k.name};
    _cache = [
      for (final e in examples)
        if (_keyNames.containsKey(e.keyId))
          _Anchor(e.keyId, VectorCodec.decode(e.vector))
    ];
  }

  void invalidate() => _cache = null;

  Future<MatchResult> match(String input) async {
    if (_cache == null) await warmUp();
    final v = await embedder.embed(input);

    // Exact-name shortcut: if a key's name appears as a whole word in the
    // log ("gym leg day"), that key wins outright. No vector maths, and it
    // is right almost every time. Longest name wins on ties.
    final words = input.toLowerCase().split(RegExp(r'[^a-z0-9]+')).toSet();
    int? named;
    for (final e in _keyNames.entries) {
      final n = e.value.toLowerCase();
      if (words.contains(n) && (named == null || n.length > _keyNames[named]!.length)) {
        named = e.key;
      }
    }
    if (named != null && !await settings.inTrainingMode()) {
      return MatchResult(MatchDecision.autoAssign,
          [KeyScore(named, _keyNames[named]!, 1.0)], v);
    }

    final best = <int, double>{}; // keyId -> max similarity
    for (final a in _cache!) {
      final s = VectorCodec.cosine(v, a.vector);
      if (s > (best[a.keyId] ?? -2)) best[a.keyId] = s;
    }

    final ranked = best.entries
        .map((e) => KeyScore(e.key, _keyNames[e.key] ?? '?', e.value))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = ranked.take(3).toList();

    final autoT = await settings.autoAssignThreshold();
    final pickerT = await settings.pickerThreshold();
    final isTraining = await settings.inTrainingMode();

    MatchDecision decision;
    if (!isTraining && top.isNotEmpty && top.first.score >= autoT) {
      decision = MatchDecision.autoAssign;
    } else if (top.isNotEmpty && top.first.score >= pickerT) {
      decision = MatchDecision.picker;
    } else {
      decision = MatchDecision.newKey;
    }
    return MatchResult(decision, top, v);
  }

  /// Persist the user's outcome as a training anchor.
  /// [corrected] = true when the user overrode an auto-assign or picked a
  /// key other than rank 1 (feeds the correction-rate metric).
  Future<void> recordOutcome({
    required int keyId,
    required String inputText,
    required Float32List inputVector,
    required bool corrected,
  }) async {
    await db.insertExample(KeyExamplesCompanion.insert(
      keyId: keyId,
      exampleText: inputText,
      vector: VectorCodec.encode(inputVector),
      source: corrected ? 'corrected' : 'confirmed',
    ));
    invalidate();
  }

  /// Create a brand-new key seeded with this input as its first anchor.
  Future<int> createKeyWithSeed(
      String name, String inputText, Float32List inputVector) async {
    final existing = await db.keyByName(name);
    final keyId = existing?.id ?? await db.createKey(name);
    await db.insertExample(KeyExamplesCompanion.insert(
      keyId: keyId,
      exampleText: inputText,
      vector: VectorCodec.encode(inputVector),
      source: 'seed',
    ));
    invalidate();
    return keyId;
  }
}

class _Anchor {
  _Anchor(this.keyId, this.vector);
  final int keyId;
  final Float32List vector;
}
