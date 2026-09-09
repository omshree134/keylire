import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/db/database.dart' as db;
import '../../data/db/database.dart' hide Key;
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<db.Key> _keys = const [];
  bool _notifications = false;
  bool _training = false;
  bool _dev = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final s = ServicesScope.of(context);
    final keys = await s.db.activeKeys();
    keys.sort((a, b) => a.name.compareTo(b.name));
    final n = await s.settings.notificationsEnabled();
    final t = await s.settings.inTrainingMode();
    if (mounted) {
      setState(() {
        _keys = keys;
        _notifications = n;
        _training = t;
      });
    }
  }

  // ---------------------------------------------------------------- keys

  Future<void> _keySheet(db.Key k) async {
    final s = ServicesScope.of(context);
    final dl = Dl.of(context);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dl.x2),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(k.name, style: Theme.of(ctx).textTheme.titleLarge)),
            ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('Rename'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final n = await _ask('Rename key', k.name);
                  if (n != null && n.isNotEmpty && n != k.name) {
                    await s.db.updateKey(k.id, KeysCompanion(name: Value(n)));
                    await s.matcher.warmUp();
                    _load();
                  }
                }),
            ListTile(
                leading: const Icon(Icons.merge_type),
                title: const Text('Merge into another key'),
                subtitle: const Text('Moves every entry and example, then archives this one'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final target = await _pickKey(exclude: k.id);
                  if (target == null) return;
                  await s.db.customStatement('UPDATE events SET key_id = ${target.id} WHERE key_id = ${k.id}');
                  await s.db.customStatement('UPDATE key_examples SET key_id = ${target.id} WHERE key_id = ${k.id}');
                  await s.db.customStatement('UPDATE list_items SET key_id = ${target.id} WHERE key_id = ${k.id}');
                  await s.db.updateKey(k.id, const KeysCompanion(isArchived: Value(true)));
                  await s.matcher.warmUp();
                  _load();
                }),
            ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive'),
                subtitle: const Text('Hidden from chips and pickers; entries stay'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await s.db.updateKey(k.id, const KeysCompanion(isArchived: Value(true)));
                  await s.matcher.warmUp();
                  _load();
                }),
          ]),
        ),
      ),
    );
  }

  Future<db.Key?> _pickKey({required int exclude}) => showModalBottomSheet<db.Key>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [for (final k in _keys.where((k) => k.id != exclude)) ListTile(title: Text(k.name), onTap: () => Navigator.pop(ctx, k))],
          ),
        ),
      );

  Future<void> _createKey() async {
    final s = ServicesScope.of(context);
    final name = await _ask('New key', '');
    if (name != null && name.trim().isNotEmpty) {
      final clean = name.trim().toLowerCase();
      final existing = await s.db.keyByName(clean);
      if (existing == null) {
        final v = await s.matcher.embedder.embed(clean);
        await s.matcher.createKeyWithSeed(clean, clean, v);
      } else if (existing.isArchived) {
        await s.db.updateKey(existing.id, const KeysCompanion(isArchived: Value(false)));
      }
      await s.matcher.warmUp();
      _load();
    }
  }

  Future<String?> _ask(String title, String initial, {bool obscure = false}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, obscureText: obscure),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim().toLowerCase()), child: const Text('Save')),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- backup

  Future<void> _export() async {
    final s = ServicesScope.of(context);
    final pass = await _ask('Passphrase for this backup', '', obscure: true);
    if (pass == null || pass.length < 6) return;
    final f = await s.export.exportEncrypted(pass);
    await Clipboard.setData(ClipboardData(text: f.path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${p.basename(f.path)} — path copied')));
    }
  }

  Future<void> _restore() async {
    final s = ServicesScope.of(context);
    final r = await FilePicker.platform.pickFiles();
    final path = r?.files.single.path;
    if (path == null) return;
    final pass = await _ask('Passphrase', '', obscure: true);
    if (pass == null) return;
    try {
      await s.export.restoreEncrypted(File(path), pass);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't restore: $e")));
    }
  }

  Future<void> _exportCorrections() async {
    final s = ServicesScope.of(context);
    final rows = await s.db.allCorrections();
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln(jsonEncode({'in': r.rawText, 'field': r.field, 'predicted': r.predicted, 'corrected': r.corrected}));
    }
    final dir = await getApplicationDocumentsDirectory();
    final f = File(p.join(dir.path, 'exports', 'corrections-${DateTime.now().millisecondsSinceEpoch}.jsonl'));
    await f.parent.create(recursive: true);
    await f.writeAsString(buf.toString());
    await Clipboard.setData(ClipboardData(text: f.path));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${rows.length} corrections — path copied')));
  }

  Future<void> _deleteAllPhotos() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete all photos?'),
        content: const Text('Entries stay. The image files are removed from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
    if (await dir.exists()) await dir.delete(recursive: true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final s = ServicesScope.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(dl.x5, dl.x3, dl.x5, dl.x10),
      children: [
        Text('Settings', style: theme.textTheme.displaySmall),
        SizedBox(height: dl.x5),

        Text('Your keys', style: theme.textTheme.titleSmall),
        Text('Keys are your own words for the things you do.', style: theme.textTheme.bodySmall),
        SizedBox(height: dl.x2),
        Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('New key'),
            onPressed: _createKey,
          ),
          for (final k in _keys) ActionChip(label: Text(k.name), onPressed: () => _keySheet(k)),
        ]),

        SizedBox(height: dl.x6),
        Text('Learning', style: theme.textTheme.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Confirm every key for two weeks'),
          subtitle: const Text('Nothing files itself until you\'ve taught it. Turn off when it feels right.'),
          value: _training,
          onChanged: (v) async {
            if (v) {
              await s.settings.startTrainingMode();
            } else {
              await s.db.putSetting('training_mode_until', '');
            }
            _load();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me at usual times'),
          subtitle: const Text('One notification with the key ready to tap. Off by default.'),
          value: _notifications,
          onChanged: (v) async {
            await s.settings.setNotificationsEnabled(v);
            _load();
          },
        ),

        SizedBox(height: dl.x6),
        Text('Privacy', style: theme.textTheme.titleSmall),
        Text('Everything Keyva does — matching, summaries, photo recognition — happens on this phone. '
            'Nothing is uploaded. There is no account.',
            style: theme.textTheme.bodyMedium),
        SizedBox(height: dl.x2),
        _tile(Icons.hide_image_outlined, 'Delete all photos', _deleteAllPhotos),

        SizedBox(height: dl.x6),
        Text('Backup', style: theme.textTheme.titleSmall),
        _tile(Icons.lock_outline, 'Save an encrypted backup', _export, sub: 'One .keyva file, passphrase-protected. The passphrase is not stored anywhere.'),
        _tile(Icons.restore, 'Restore from a backup', _restore),

        SizedBox(height: dl.x6),
        InkWell(
          onTap: () => setState(() => _dev = !_dev),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dl.x2),
            child: Text('Keyva 0.2 · local-first', style: theme.textTheme.bodySmall),
          ),
        ),
        if (_dev) ...[
          _tile(Icons.download_outlined, 'Export corrections (jsonl)', _exportCorrections,
              sub: 'Every time you fixed a key or a time. Feeds the phrase corpus.'),
          FutureBuilder(
            future: Future.wait([
              s.metrics.medianCaptureSeconds(),
              s.metrics.logsPerDay(),
              s.metrics.daysSinceLastLog(),
              s.metrics.autoAssignCorrectionRate(),
              s.metrics.plannedDoneRate(),
            ]),
            builder: (context, snap) {
              final v = snap.data;
              if (v == null) return const SizedBox.shrink();
              String f(num? x, [int d = 1]) => x == null ? '—' : x.toStringAsFixed(d);
              return Padding(
                padding: EdgeInsets.only(top: dl.x2),
                child: Text(
                  'median ${f(v[0])} s/log · ${f(v[1])} logs/day · ${v[2] ?? '—'} days since last · '
                  'correction ${f((v[3] ?? 0) * 100, 0)}% · plans done ${f((v[4] ?? 0) * 100, 0)}%',
                  style: DlType.mono(context, size: 11),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _tile(IconData i, String t, VoidCallback f, {String? sub}) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(i, size: 20),
        title: Text(t),
        subtitle: sub == null ? null : Text(sub),
        onTap: f,
      );
}
