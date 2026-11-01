import 'package:flutter/material.dart';

import '../../services/matching/key_matcher.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';

/// Bottom sheet shown when the matcher isn't confident. Top-3 candidates
/// with their similarity drawn as a quiet underline bar, plus a "new key"
/// field. Keyboard-safe on both platforms; sized to any phone.
Future<void> showKeyPickerSheet(
  BuildContext context, {
  required int eventId,
  required String rawText,
  required MatchResult match,
  String? suggestedName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => _PickerBody(
        eventId: eventId,
        rawText: rawText,
        match: match,
        suggestedName: suggestedName),
  );
}

class _PickerBody extends StatefulWidget {
  const _PickerBody(
      {required this.eventId,
      required this.rawText,
      required this.match,
      this.suggestedName});
  final int eventId;
  final String rawText;
  final MatchResult match;
  final String? suggestedName;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final _newKey = TextEditingController(text: widget.suggestedName ?? '');
  bool _working = false;

  Future<void> _pick(int keyId) async {
    if (_working) return;
    setState(() => _working = true);
    final s = ServicesScope.of(context);
    await s.capture
        .resolvePick(widget.eventId, widget.match, keyId, widget.rawText);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _create([String? directName]) async {
    final name = (directName ?? _newKey.text).trim().toLowerCase();
    if (name.isEmpty || _working) return;
    setState(() => _working = true);
    final s = ServicesScope.of(context);
    await s.capture
        .resolveNewKey(widget.eventId, widget.match, name, widget.rawText);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final newKeyFirst = widget.match.top.isEmpty ||
        widget.match.top.first.score < 0.60;
    final cleanSuggested = widget.suggestedName?.trim().toLowerCase();
    final candidateNames = widget.match.top.map((c) => c.keyName.toLowerCase()).toSet();
    final hasUniqueSuggested = cleanSuggested != null &&
        cleanSuggested.isNotEmpty &&
        !candidateNames.contains(cleanSuggested);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
          left: dl.x5,
          right: dl.x5,
          top: dl.x5,
          bottom: MediaQuery.viewInsetsOf(context).bottom + dl.x5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.rawText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge),
          SizedBox(height: dl.x1),
          Row(
            children: [
              Text('File under', style: theme.textTheme.bodySmall),
              const Spacer(),
              if (hasUniqueSuggested)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14),
                  label: Text('New key: $cleanSuggested'),
                  onPressed: () => _create(cleanSuggested),
                ),
            ],
          ),
          SizedBox(height: dl.x3),
          if (newKeyFirst) _newKeyField(theme, dl, autofocus: true),
          for (final k in widget.match.top) _candidate(k, theme, dl),
          if (!newKeyFirst) ...[
            SizedBox(height: dl.x2),
            _newKeyField(theme, dl, autofocus: false),
          ],
        ],
      ),
    );
  }

  Widget _candidate(KeyScore k, ThemeData theme, Dl dl) {
    final hue = arcColorFor(DateTime.now());
    return InkWell(
      onTap: () => _pick(k.keyId),
      child: Container(
        constraints: const BoxConstraints(minHeight: Dl.tapMin),
        padding: EdgeInsets.symmetric(vertical: dl.x2),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline))),
        child: Row(
          children: [
            Expanded(child: Text(k.keyName, style: theme.textTheme.bodyLarge)),
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(k.score * 100).round()}%',
                      style: DlType.mono(context, size: 11)),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: k.score.clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: theme.colorScheme.outline,
                      color: hue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newKeyField(ThemeData theme, Dl dl, {required bool autofocus}) {
    return Padding(
      padding: EdgeInsets.only(top: dl.x3, bottom: dl.x2),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newKey,
              autofocus: autofocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
              decoration: const InputDecoration(
                hintText: 'New key name…',
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: dl.x2),
          FilledButton.icon(
            onPressed: () => _create(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newKey.dispose();
    super.dispose();
  }
}
