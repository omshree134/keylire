import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime_plus/onnxruntime_plus.dart';

import 'embedding_service.dart';

/// Same model, same vectors as OnnxEmbeddingService, but inference runs on
/// a long-lived worker isolate so typing, speech and the ribbon never wait
/// on a forward pass. Requests are serialised in the worker, which is what
/// we want: one session, no contention.
class IsolateEmbeddingService implements EmbeddingService {
  IsolateEmbeddingService({
    this.modelAsset = 'assets/models/minilm-l6-v2-int8.onnx',
    this.vocabAsset = 'assets/models/vocab.txt',
    this.maxTokens = 64,
  });

  final String modelAsset;
  final String vocabAsset;
  final int maxTokens;

  @override
  final int dim = 384;

  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  StreamSubscription<dynamic>? _sub;
  final _pending = <int, Completer<Float32List>>{};
  int _seq = 0;

  @override
  Future<void> init() async {
    final raw = await rootBundle.load(modelAsset);
    final vocab = await rootBundle.loadString(vocabAsset);
    final bytes = raw.buffer.asUint8List(raw.offsetInBytes, raw.lengthInBytes);

    _fromWorker = ReceivePort();
    final ready = Completer<SendPort>();
    _sub = _fromWorker!.listen((msg) {
      if (msg is SendPort) {
        ready.complete(msg);
        return;
      }
      if (msg is _Reply) {
        final c = _pending.remove(msg.id);
        if (c == null) return;
        if (msg.vector != null) {
          c.complete(msg.vector);
        } else {
          c.completeError(StateError(msg.error ?? 'embed failed'));
        }
      }
    });

    _isolate = await Isolate.spawn<_Boot>(
      _workerMain,
      _Boot(
        model: TransferableTypedData.fromList([bytes]),
        vocab: vocab,
        reply: _fromWorker!.sendPort,
        maxTokens: maxTokens,
        dim: dim,
      ),
      debugName: 'keylire-embed',
      errorsAreFatal: true,
    );
    _toWorker = await ready.future.timeout(const Duration(seconds: 20));
  }

  @override
  Future<Float32List> embed(String text) {
    final port = _toWorker;
    if (port == null) throw StateError('IsolateEmbeddingService.init() not called');
    final id = _seq++;
    final c = Completer<Float32List>();
    _pending[id] = c;
    port.send(_Request(id, text));
    return c.future;
  }

  @override
  void dispose() {
    _toWorker?.send(const _Close());
    _sub?.cancel();
    _fromWorker?.close();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    for (final c in _pending.values) {
      c.completeError(StateError('embedder disposed'));
    }
    _pending.clear();
    _isolate = null;
    _toWorker = null;
  }
}

// ----------------------------------------------------------------- worker

class _Boot {
  _Boot({required this.model, required this.vocab, required this.reply,
      required this.maxTokens, required this.dim});
  final TransferableTypedData model;
  final String vocab;
  final SendPort reply;
  final int maxTokens;
  final int dim;
}

class _Request {
  const _Request(this.id, this.text);
  final int id;
  final String text;
}

class _Reply {
  const _Reply(this.id, {this.vector, this.error});
  final int id;
  final Float32List? vector;
  final String? error;
}

class _Close {
  const _Close();
}

@pragma('vm:entry-point')
void _workerMain(_Boot boot) {
  OrtEnv.instance.init();
  final session = OrtSession.fromBuffer(
      boot.model.materialize().asUint8List(), OrtSessionOptions());
  final tokenizer = WordPieceTokenizer.fromVocab(boot.vocab);

  final rx = ReceivePort();
  boot.reply.send(rx.sendPort);

  rx.listen((msg) {
    if (msg is _Close) {
      session.release();
      OrtEnv.instance.release();
      rx.close();
      return;
    }
    if (msg is _Request) {
      try {
        final v = runMiniLm(session, tokenizer, msg.text,
            maxTokens: boot.maxTokens, dim: boot.dim);
        boot.reply.send(_Reply(msg.id, vector: v));
      } catch (e) {
        boot.reply.send(_Reply(msg.id, error: e.toString()));
      }
    }
  });
}

