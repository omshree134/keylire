import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime_plus/onnxruntime_plus.dart';

/// Contract: any embedder returns an L2-normalised float32 vector of [dim].
/// Vectors are persisted as little-endian float32 BLOBs of exactly
/// dim * 4 bytes - this convention is relied on by KeyMatcher.
abstract class EmbeddingService {
  int get dim;
  Future<void> init();
  Future<Float32List> embed(String text);
  void dispose();
}

/// all-MiniLM-L6-v2 (int8 ONNX, ~23MB) via ONNX Runtime Mobile.
/// Assets expected:
///   assets/models/minilm-l6-v2-int8.onnx
///   assets/models/vocab.txt            (BERT WordPiece vocab)
///
/// Swapping models later (EmbeddingGemma / bge-small / multilingual):
/// implement EmbeddingService with the new dim; stored vectors must be
/// re-embedded from key_examples.example_text (kept for exactly this reason).
class OnnxEmbeddingService implements EmbeddingService {
  OnnxEmbeddingService({
    this.modelAsset = 'assets/models/minilm-l6-v2-int8.onnx',
    this.vocabAsset = 'assets/models/vocab.txt',
    this.maxTokens = 64, // log lines are short; keeps latency ~ms
  });

  final String modelAsset;
  final String vocabAsset;
  final int maxTokens;

  @override
  final int dim = 384;

  OrtSession? _session;
  late WordPieceTokenizer _tokenizer;

  @override
  Future<void> init() async {
    OrtEnv.instance.init();
    final raw = await rootBundle.load(modelAsset);
    _session =
        OrtSession.fromBuffer(raw.buffer.asUint8List(), OrtSessionOptions());
    final vocab = await rootBundle.loadString(vocabAsset);
    _tokenizer = WordPieceTokenizer.fromVocab(vocab);
  }

  @override
  Future<Float32List> embed(String text) async {
    final session = _session;
    if (session == null) {
      throw StateError('OnnxEmbeddingService.init() not called');
    }
    return runMiniLm(session, _tokenizer, text, maxTokens: maxTokens, dim: dim);
  }

  @override
  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}

/// Synchronous MiniLM forward pass + mean pool + L2 normalise.
/// Shared by the main-isolate service and the worker isolate.
Float32List runMiniLm(OrtSession session, WordPieceTokenizer tokenizer, String text,
    {int maxTokens = 64, int dim = 384}) {
  final ids = tokenizer.encode(text, maxTokens: maxTokens);
  final n = ids.length;
  final inputIds = OrtValueTensor.createTensorWithDataList([Int64List.fromList(ids)], [1, n]);
  final mask = OrtValueTensor.createTensorWithDataList([Int64List.fromList(List.filled(n, 1))], [1, n]);
  final types = OrtValueTensor.createTensorWithDataList([Int64List.fromList(List.filled(n, 0))], [1, n]);

  final outputs = session.run(OrtRunOptions(), {
    'input_ids': inputIds,
    'attention_mask': mask,
    'token_type_ids': types,
  });
  try {
    final hidden = (outputs.first!.value as List)[0] as List;
    final pooled = Float32List(dim);
    for (var t = 0; t < n; t++) {
      final row = hidden[t] as List;
      for (var d = 0; d < dim; d++) {
        pooled[d] += (row[d] as num).toDouble();
      }
    }
    var norm = 0.0;
    for (var d = 0; d < dim; d++) {
      pooled[d] /= n;
      norm += pooled[d] * pooled[d];
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var d = 0; d < dim; d++) {
        pooled[d] /= norm;
      }
    }
    return pooled;
  } finally {
    for (final o in outputs) {
      o?.release();
    }
    inputIds.release();
    mask.release();
    types.release();
  }
}

/// Minimal BERT WordPiece tokenizer - enough for short log lines.
/// Lowercases, greedy-longest-match subwords, punctuation as own tokens.
class WordPieceTokenizer {
  WordPieceTokenizer(this._vocab)
      : _cls = _vocab['[CLS]'] ?? 101,
        _sep = _vocab['[SEP]'] ?? 102,
        _unk = _vocab['[UNK]'] ?? 100;

  factory WordPieceTokenizer.fromVocab(String vocabFile) {
    final map = <String, int>{};
    final lines = vocabFile.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final tok = lines[i].trim();
      if (tok.isNotEmpty) map[tok] = i;
    }
    return WordPieceTokenizer(map);
  }

  final Map<String, int> _vocab;
  final int _cls, _sep, _unk;

  List<int> encode(String text, {int maxTokens = 64}) {
    final ids = <int>[_cls];
    for (final word in _basicSplit(text)) {
      ids.addAll(_wordPiece(word));
      if (ids.length >= maxTokens - 1) break;
    }
    if (ids.length > maxTokens - 1) ids.length = maxTokens - 1;
    ids.add(_sep);
    return ids;
  }

  Iterable<String> _basicSplit(String text) sync* {
    final lowered = text.toLowerCase();
    final buf = StringBuffer();
    for (final rune in lowered.runes) {
      final ch = String.fromCharCode(rune);
      final isWord = RegExp(r'[a-z0-9]').hasMatch(ch);
      if (isWord) {
        buf.write(ch);
      } else {
        if (buf.isNotEmpty) {
          yield buf.toString();
          buf.clear();
        }
        if (ch.trim().isNotEmpty) yield ch;
      }
    }
    if (buf.isNotEmpty) yield buf.toString();
  }

  List<int> _wordPiece(String word) {
    if (_vocab.containsKey(word)) return [_vocab[word]!];
    final pieces = <int>[];
    var start = 0;
    while (start < word.length) {
      var end = word.length;
      int? id;
      while (end > start) {
        final sub = (start == 0 ? '' : '##') + word.substring(start, end);
        if (_vocab.containsKey(sub)) {
          id = _vocab[sub];
          break;
        }
        end--;
      }
      if (id == null) return [_unk];
      pieces.add(id);
      start = end;
    }
    return pieces;
  }
}

/// BLOB <-> vector helpers (float32 little-endian). Single source of truth
/// for the storage convention.
class VectorCodec {
  static Uint8List encode(Float32List v) =>
      v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes).sublist(0);

  static Float32List decode(Uint8List blob) =>
      blob.buffer.asFloat32List(blob.offsetInBytes, blob.lengthInBytes ~/ 4);

  static double cosine(Float32List a, Float32List b) {
    // Both vectors are L2-normalised at creation, so cosine == dot product.
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}
