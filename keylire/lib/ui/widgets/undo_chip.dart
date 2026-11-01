import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/matching/key_matcher.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import 'key_picker_sheet.dart';

OverlayEntry? _active;

void dismissUndoChip() {
  if (_active != null && _active!.mounted) _active!.remove();
  _active = null;
}

/// Ten seconds, one chip: "Filed under gym — Change · Add note".
/// For plans: "Planned 18:00 under gym". Tap Change reopens the picker as a
/// correction. Tap Add note opens a one-field sheet. Expiry is silent.
void showUndoChip(
  BuildContext context, {
  required int eventId,
  required String? keyName,
  required String rawText,
  required MatchResult match,
  required VoidCallback onChanged,
  bool planned = false,
  DateTime? at,
  bool offerNote = false,
}) {
  dismissUndoChip();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _UndoChip(
      keyName: keyName,
      planned: planned,
      at: at,
      offerNote: offerNote,
      onChange: () async {
        dismissUndoChip();
        await showKeyPickerSheet(context, eventId: eventId, rawText: rawText, match: match);
        onChanged();
      },
      onNote: () async {
        dismissUndoChip();
        final s = ServicesScope.of(context);
        final note = await _askNote(context, rawText);
        if (note == null) {
          final e = await s.db.eventById(eventId);
          await s.capture.noteIgnored(e?.keyId);
        } else {
          await s.capture.setNote(eventId, note);
        }
        onChanged();
      },
      onExpired: () async {
        dismissUndoChip();
        if (offerNote) {
          final s = ServicesScope.of(context);
          final e = await s.db.eventById(eventId);
          await s.capture.noteIgnored(e?.keyId);
        }
      },
    ),
  );
  _active = entry;
  overlay.insert(entry);
}

Future<String?> _askNote(BuildContext context, String rawText) {
  final c = TextEditingController();
  final dl = Dl.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(dl.x5, dl.x4, dl.x5, MediaQuery.viewInsetsOf(ctx).bottom + dl.x5),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rawText, style: Theme.of(ctx).textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
        SizedBox(height: dl.x3),
        TextField(
          controller: c,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'What\'s worth remembering'),
        ),
        SizedBox(height: dl.x4),
        Row(children: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
          const Spacer(),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save note')),
        ]),
      ]),
    ),
  );
}

class _UndoChip extends StatefulWidget {
  const _UndoChip({
    required this.keyName,
    required this.planned,
    required this.at,
    required this.offerNote,
    required this.onChange,
    required this.onNote,
    required this.onExpired,
  });
  final String? keyName;
  final bool planned;
  final DateTime? at;
  final bool offerNote;
  final VoidCallback onChange, onNote, onExpired;

  @override
  State<_UndoChip> createState() => _UndoChipState();
}

class _UndoChipState extends State<_UndoChip> with SingleTickerProviderStateMixin {
  static const window = Duration(seconds: 10);
  late final _drain = AnimationController(vsync: this, duration: window);
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reducedMotion(context)) {
        _fallback = Timer(window, widget.onExpired);
      } else {
        _drain.forward().whenComplete(widget.onExpired);
      }
    });
  }

  @override
  void dispose() {
    _drain.dispose();
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    String label;
    if (widget.keyName == null) {
      label = 'Saved';
    } else if (widget.planned && widget.at != null) {
      final t = '${widget.at!.hour.toString().padLeft(2, '0')}:${widget.at!.minute.toString().padLeft(2, '0')}';
      label = 'Planned $t under ${widget.keyName}';
    } else {
      label = 'Filed under ${widget.keyName}';
    }

    return Positioned(
      left: dl.x4,
      right: dl.x4,
      bottom: 150 + MediaQuery.paddingOf(context).bottom,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: dl.x4, vertical: dl.x2),
            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 16,
                height: 16,
                child: AnimatedBuilder(
                  animation: _drain,
                  builder: (_, __) => CircularProgressIndicator(
                      value: 1 - _drain.value, strokeWidth: 2, color: on, backgroundColor: on.withValues(alpha: 0.25)),
                ),
              ),
              SizedBox(width: dl.x3),
              Text(label, style: theme.textTheme.bodyMedium!.copyWith(color: on)),
              if (widget.keyName != null) ...[
                SizedBox(width: dl.x3),
                _link('Change', on, widget.onChange),
              ],
              if (widget.offerNote) ...[
                SizedBox(width: dl.x3),
                _link('Add note', on, widget.onNote),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _link(String t, Color c, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Text(t,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: c, decoration: TextDecoration.underline, decorationColor: c)),
      );
}
