import 'dart:math' as math;
import 'dart:typed_data';

import 'embedding_service.dart';

/// DEV-ONLY fallback so the app runs before the ONNX model asset exists
/// (Phase 1 has a manual picker anyway). Deterministic hashed
/// bag-of-words: each lowercase token maps to 3 dimensions, vector is
/// L2-normalised. Matches exact/overlapping wording ("gym" ~ "gym leg day")
/// but has NO semantic understanding - "workout" will not match "gym".
/// main.dart swaps in OnnxEmbeddingService automatically once the model
/// asset loads. Never ship this as the real matcher.
class HashingEmbeddingService implements EmbeddingService {
  @override
  final int dim = 384;

  @override
  Future<void> init() async {}

  @override
  Future<Float32List> embed(String text) async {
    final v = Float32List(dim);
    final tokens = text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty);
    for (final t in tokens) {
      var h = 2166136261; // FNV-1a
      for (final c in t.codeUnits) {
        h = ((h ^ c) * 16777619) & 0xFFFFFFFF;
      }
      for (var k = 0; k < 3; k++) {
        final idx = (h >> (k * 8)) % dim;
        v[idx] += 1.0;
      }
    }
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < dim; i++) {
        v[i] /= norm;
      }
    }
    return v;
  }

  @override
  void dispose() {}
}
