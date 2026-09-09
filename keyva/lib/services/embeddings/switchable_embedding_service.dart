import 'dart:typed_data';

import '../../core/config/ai_config.dart';
import 'embedding_service.dart';
import 'hashing_embedding_service.dart';

/// Starts as the (instant, semantics-free) hashing embedder so first paint is
/// never blocked, then swaps to the ONNX model once it has loaded. Both are
/// 384-dim, so the matcher does not care which is live - but stored vectors
/// from two different embedders must never be compared, which is why
/// main.dart re-embeds every key_example when [id] changes.
class SwitchableEmbeddingService implements EmbeddingService {
  SwitchableEmbeddingService() : _inner = HashingEmbeddingService();

  EmbeddingService _inner;
  String _id = AiConfig.hashingEmbedderId;

  /// Stable identifier of whatever is currently answering [embed].
  String get id => _id;
  bool get isSemantic => _id != AiConfig.hashingEmbedderId;

  @override
  int get dim => _inner.dim;

  @override
  Future<void> init() => _inner.init();

  @override
  Future<Float32List> embed(String text) => _inner.embed(text);

  /// Try to upgrade to [candidate]. Returns true if it is now live.
  Future<bool> upgradeTo(EmbeddingService candidate, String id) async {
    try {
      await candidate.init();
      if (candidate.dim != _inner.dim) {
        candidate.dispose();
        return false;
      }
      final old = _inner;
      _inner = candidate;
      _id = id;
      old.dispose();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() => _inner.dispose();
}
