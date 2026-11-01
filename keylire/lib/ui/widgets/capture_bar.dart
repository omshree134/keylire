import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../data/db/database.dart';
import '../../services/capture/capture_service.dart';
import '../../services/photos/photo_understanding_service.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import 'key_picker_sheet.dart';
import 'undo_chip.dart';

/// Two rows. Chips: Bed and Up fixed at the left, then due-now, usual-now,
/// frequent. One bare line: camera, mic, text, send-when-there's-text.
/// The focused underline takes the hour's ink.
class CaptureBar extends StatefulWidget {
  const CaptureBar({super.key, required this.onLogged, this.targetDayDate});
  final Future<void> Function() onLogged;
  final String? targetDayDate;

  @override
  State<CaptureBar> createState() => _CaptureBarState();
}

class _CaptureBarState extends State<CaptureBar> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  ChipsController? _chips;
  DateTime? _openedAt;
  bool _busy = false;

  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _speechReady = false;
  bool _voiceNeedsReview = false;
  String _speechBaseText = '';
  final _picker = ImagePicker();
  StreamSubscription<String>? _bus;
  Timer? _chipDebounce;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    _focus.addListener(() {
      if (_focus.hasFocus) _openedAt ??= DateTime.now();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chips = ChipsController(ServicesScope.of(context))
        ..load(targetDayDate: widget.targetDayDate);
      _chips!.addListener(_onChipsChanged);
      _initSpeech();
    });
    _bus = WidgetActionBus.stream.listen((a) {
      if (!mounted) return;
      if (a == 'keylire://capture/camera') _pickImage(ImageSource.camera);
      if (a == 'keylire://capture/mic') _toggleListening();
      if (a == 'keylire://capture/text') _focus.requestFocus();
      if (a == 'keylire://capture/bed') _bed();
      if (a == 'keylire://capture/up') _up();
      final u = Uri.tryParse(a);
      final id = int.tryParse(u?.queryParameters['id'] ?? '');
      if (a.startsWith('keylire://capture/chip') && id != null) {
        _tapKey(id, u!.queryParameters['name'] ?? '');
      }
    });
  }

  void _onChipsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CaptureBar old) {
    super.didUpdateWidget(old);
    if (widget.targetDayDate != old.targetDayDate) {
      _chips?.load(targetDayDate: widget.targetDayDate);
    }
  }

  @override
  void dispose() {
    _bus?.cancel();
    _chipDebounce?.cancel();
    _text.removeListener(_onTextChanged);
    _text.dispose();
    _focus.dispose();
    _chips?.removeListener(_onChipsChanged);
    _chips?.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onTextChanged() {
    _chipDebounce?.cancel();
    _chipDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _chips?.load(
        targetDayDate: widget.targetDayDate,
        query: _text.text,
      );
    });
  }

  int? get _elapsed => _openedAt == null
      ? null
      : DateTime.now().difference(_openedAt!).inMilliseconds;

  void _reset() {
    _text.clear();
    _openedAt = null;
    _voiceNeedsReview = false;
    _speechBaseText = '';
    _focus.unfocus();
  }

  // ------------------------------------------------------------ doors

  Future<void> _submit({String modality = 'text'}) async {
    final raw = _text.text.trim();
    if (raw.isEmpty || _busy) return;
    final effectiveModality =
        modality == 'text' && _voiceNeedsReview ? 'voice' : modality;
    final elapsed = _elapsed;
    _reset();
    final s = ServicesScope.of(context);
    setState(() => _busy = true);
    try {
      final out = await s.capture.capture(
          rawText: raw,
          modality: effectiveModality,
          captureMs: elapsed,
          targetDayDate: widget.targetDayDate);
      await widget.onLogged();
      if (mounted) await _route(out, raw);
      _chips?.load(targetDayDate: widget.targetDayDate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tapKey(int keyId, String name) async {
    HapticFeedback.lightImpact();
    _focus.unfocus();
    final s = ServicesScope.of(context);
    await s.capture.capture(
        rawText: name,
        modality: 'widget',
        forcedKeyId: keyId,
        captureMs: _openedAt == null ? 900 : _elapsed,
        targetDayDate: widget.targetDayDate);
    await widget.onLogged();
    _chips?.load(targetDayDate: widget.targetDayDate);
  }

  /// File the current sentence under the selected key. This is different
  /// from a quick chip tap with an empty field: the user's words are kept as
  /// the event and become a personal matcher example for future suggestions.
  Future<void> _submitWithKey(int keyId) async {
    final raw = _text.text.trim();
    if (raw.isEmpty || _busy) return;
    final elapsed = _elapsed;
    final s = ServicesScope.of(context);
    setState(() => _busy = true);
    try {
      final match = await s.matcher.match(raw);
      final out = await s.capture.capture(
        rawText: raw,
        modality: 'text',
        captureMs: elapsed,
        forcedKeyId: keyId,
        targetDayDate: widget.targetDayDate,
      );
      try {
        await s.matcher.recordOutcome(
          keyId: keyId,
          inputText: raw,
          inputVector: match.inputVector,
          corrected: match.top.isNotEmpty && match.top.first.keyId != keyId,
        );
      } catch (_) {
        // The event is already safe. A failed learning write must never make
        // a successful capture look lost to the user.
      }
      _reset();
      await widget.onLogged();
      if (mounted) await _route(out, raw);
      _chips?.load(targetDayDate: widget.targetDayDate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tapChip(Chip c) async {
    if (c.isBed || c.name == 'Bed') {
      await _bed();
      return;
    }
    if (c.isUp || c.name == 'Up') {
      await _up();
      return;
    }
    if (c.plannedEventId != null) {
      HapticFeedback.mediumImpact();
      await ServicesScope.of(context)
          .capture
          .completePlanned(c.plannedEventId!);
      await widget.onLogged();
      _chips?.load(targetDayDate: widget.targetDayDate);
      return;
    }
    if (_text.text.trim().isNotEmpty) {
      await _submitWithKey(c.keyId);
      return;
    }
    await _tapKey(c.keyId, c.name);
  }

  Future<void> _bed() async {
    HapticFeedback.lightImpact();
    await ServicesScope.of(context).capture.bed(captureMs: 600);
    await widget.onLogged();
    _chips?.load(targetDayDate: widget.targetDayDate);
  }

  Future<void> _up() async {
    HapticFeedback.lightImpact();
    await ServicesScope.of(context).capture.up(captureMs: 600);
    await widget.onLogged();
    _chips?.load(targetDayDate: widget.targetDayDate);
  }

  Future<void> _route(CaptureOutcome out, String raw) async {
    final s = ServicesScope.of(context);
    switch (out.state) {
      case CaptureState.autoAssigned:
        showUndoChip(context,
            eventId: out.eventId,
            keyName: out.autoKey!.keyName,
            rawText: raw,
            match: out.match!,
            planned: out.planned,
            at: out.at,
            offerNote: out.wantsNote,
            onChanged: () => unawaited(widget.onLogged()));
      case CaptureState.needsPick:
        await showKeyPickerSheet(context,
            eventId: out.eventId,
            rawText: raw,
            match: out.match!,
            suggestedName: out.suggestedKeyName);
        await widget.onLogged();
        if (out.wantsNote && mounted) {
          showUndoChip(context,
              eventId: out.eventId,
              keyName: null,
              rawText: raw,
              match: out.match!,
              planned: out.planned,
              at: out.at,
              offerNote: true,
              onChanged: () => unawaited(widget.onLogged()));
        }
      case CaptureState.listed:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Added to your list'),
          action: SnackBarAction(
              label: 'Undo',
              onPressed: () => s.db.updateListItem(
                  out.eventId,
                  ListItemsCompanion(
                      deletedAt: Value(DateTime.now().toUtc())))),
        ));
      case CaptureState.saved:
        if (out.planned && out.at != null) {
          final t =
              '${out.at!.hour.toString().padLeft(2, '0')}:${out.at!.minute.toString().padLeft(2, '0')}';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Planned for $t')));
        }
    }
  }

  // ------------------------------------------------------------ speech

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onError: (e) {
          if (mounted) setState(() => _listening = false);
        },
        onStatus: (st) {
          if ((st == 'notListening' || st == 'done') && mounted) {
            setState(() {
              _listening = false;
              if (_text.text.trim().isNotEmpty) _voiceNeedsReview = true;
            });
          }
        },
      );
    } catch (_) {
      _speechReady = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() {
        _listening = false;
        if (_text.text.trim().isNotEmpty) _voiceNeedsReview = true;
      });
      _focus.requestFocus();
      return;
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Microphone access is needed for voice logs'),
          action: mic.isPermanentlyDenied
              ? SnackBarAction(label: 'Settings', onPressed: openAppSettings)
              : null,
        ));
      }
      return;
    }
    if (!_speechReady) await _initSpeech();
    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Speech recognition is not available on this device')));
      }
      return;
    }
    setState(() => _listening = true);
    _openedAt ??= DateTime.now();
    _speechBaseText = _text.text.trim();
    _voiceNeedsReview = false;
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        final recognized = r.recognizedWords.trim();
        final combined = [
          if (_speechBaseText.isNotEmpty) _speechBaseText,
          if (recognized.isNotEmpty) recognized,
        ].join(' ');
        setState(() {
          _text.value = TextEditingValue(
            text: combined,
            selection: TextSelection.collapsed(offset: combined.length),
          );
        });
        if (r.finalResult) {
          setState(() {
            _listening = false;
            _voiceNeedsReview = combined.isNotEmpty;
          });
          _focus.requestFocus();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(seconds: 45),
      ),
    );
  }

  // ------------------------------------------------------------- photo

  Future<void> _photoSheet() async {
    _focus.unfocus();
    final dl = Dl.of(context);
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dl.x2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ]),
        ),
      ),
    );
    if (src != null && mounted) await _pickImage(src);
  }

  Future<void> _pickImage(ImageSource src) async {
    _focus.unfocus();
    try {
      final picked = await _picker.pickImage(
          source: src, imageQuality: 85, maxWidth: 1280, maxHeight: 1280);
      if (picked == null || !mounted) return;
      final s = ServicesScope.of(context);
      final dir = Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final saved = await File(picked.path).copy(p.join(dir.path,
          'photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}'));

      final typed = _text.text.trim();
      final out = await s.capture.capture(
          rawText: typed.isNotEmpty ? typed : 'Photo',
          modality: 'photo',
          captureMs: _elapsed,
          photoPath: saved.path,
          targetDayDate: widget.targetDayDate);
      _reset();
      await widget.onLogged();
      unawaited(_maybeOfferBetterPhotoModel());

      // On-device understanding, off the UI thread. Never a network call.
      unawaited(() async {
        final u = await s.photos.understand(saved);
        if (!mounted) return;
        final line = typed.isNotEmpty ? typed : u.description;
        await s.photos
            .applyToEvent(out.eventId, u, keepUserText: typed.isNotEmpty);

        // Auto-assign key so photo is never left unfiled:
        final matchText = u.keyHint ?? line;
        final m = await s.matcher.match(matchText);
        if (!mounted) return;
        int? assignedKeyId;
        String assignedKeyName;
        if (m.top.isNotEmpty) {
          assignedKeyId = m.top.first.keyId;
          assignedKeyName = m.top.first.keyName;
          await s.capture.resolvePick(out.eventId, m, assignedKeyId, line);
        } else if (u.keyHint != null && u.keyHint!.isNotEmpty) {
          assignedKeyId =
              await s.capture.resolveNewKey(out.eventId, m, u.keyHint!, line);
          assignedKeyName = u.keyHint!;
        } else {
          assignedKeyId =
              await s.capture.resolveNewKey(out.eventId, m, 'photo', line);
          assignedKeyName = 'photo';
        }
        await widget.onLogged();
        if (mounted) {
          showUndoChip(context,
              eventId: out.eventId,
              keyName: assignedKeyName,
              rawText: line,
              match: m,
              planned: out.planned,
              at: out.at,
              offerNote: out.wantsNote,
              onChanged: () => unawaited(widget.onLogged()));
        }
      }());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't save photo: $e")));
      }
    }
  }

  Future<void> _maybeOfferBetterPhotoModel() async {
    final s = ServicesScope.of(context);
    final captioner = s.photos.captioner;
    if (captioner == null || await s.settings.photoModelPrompted()) return;
    final status = await captioner.status();
    if (!mounted || status != PhotoModelStatus.downloadable) return;
    await s.settings.setPhotoModelPrompted(true);
    if (!mounted) return;
    final download = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Better photo understanding?'),
        content: const Text(
          'This phone can download an optional Gemini Nano model for clearer photo descriptions. '
          'It runs on-device and your photos are not uploaded. The current photo will still be saved normally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (download != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading the on-device photo model…')),
    );
    try {
      await captioner.download();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Better photo descriptions are ready')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model download failed. You can retry in Settings.'),
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final nowHue = arcColorFor(DateTime.now());
    final soft = theme.colorScheme.onSurfaceVariant;
    final chips = _chips?.chips ?? const <Chip>[];

    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x3, dl.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in chips) ...[
                      ActionChip(
                        avatar: c.isBed || c.name == 'Bed'
                            ? const Icon(Icons.circle,
                                size: 7, color: DlColors.night)
                            : c.isUp || c.name == 'Up'
                                ? const Icon(Icons.circle,
                                    size: 7, color: DlColors.dawn)
                                : c.plannedEventId != null
                                    ? Icon(Icons.radio_button_unchecked,
                                        size: 14, color: arcColorFor(c.at!))
                                    : c.minute != null
                                        ? Icon(Icons.circle,
                                            size: 7,
                                            color: arcColorOfMinute(c.minute!))
                                        : null,
                        label: Text(c.plannedEventId != null
                            ? '${c.name} ${c.at!.hour.toString().padLeft(2, '0')}:${c.at!.minute.toString().padLeft(2, '0')}'
                            : c.selectorLabel),
                        onPressed: () => _tapChip(c),
                      ),
                      SizedBox(width: dl.x2),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  _icon(Icons.camera_alt_outlined, 'Attach photo', soft,
                      _photoSheet),
                  _icon(
                      _listening ? Icons.mic : Icons.mic_none_outlined,
                      _listening ? 'Stop' : 'Voice log',
                      _listening ? DlColors.danger : soft,
                      _toggleListening),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      maxLength: 500,
                      buildCounter: (context,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      onTap: () => _openedAt ??= DateTime.now(),
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: _listening
                            ? 'Listening…'
                            : _voiceNeedsReview
                                ? 'Review the transcript, then send'
                                : 'One line — what happened, or what\'s next',
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: nowHue, width: 1.5)),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _text,
                    builder: (context, v, _) => AnimatedOpacity(
                      opacity: v.text.trim().isEmpty ? 0 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: IconButton(
                        tooltip: 'Log it',
                        onPressed:
                            v.text.trim().isEmpty ? null : () => _submit(),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(34, 34),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData i, String tip, Color c, VoidCallback onTap) =>
      IconButton(
        tooltip: tip,
        icon: Icon(i, size: 20, color: c),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
      );
}
