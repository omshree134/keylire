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
import '../../services/backup/backup_file_bridge.dart';
import '../../services/cloud/cloud_provider.dart';
import '../../services/entitlements/entitlements_service.dart';
import '../../services/photos/photo_understanding_service.dart';
import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import 'how_to_use_screen.dart';
import 'saved_meals_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<db.Key> _keys = const [];
  bool _training = false;
  bool _dev = false;
  PhotoModelStatus _photoModelStatus = PhotoModelStatus.unsupported;
  bool _photoModelBusy = false;
  bool _hasPasscode = false;
  bool _biometric = false;
  bool _notifications = false;
  bool _nudgeMorning = true;
  bool _nudgeEvening = true;
  bool _cloudAvailable = false;
  Tier _tier = Tier.free;
  final Map<CloudFeature, bool> _features = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final s = ServicesScope.of(context);
    final keys = await s.db.activeKeys();
    keys.sort((a, b) => a.name.compareTo(b.name));
    final t = await s.settings.inTrainingMode();
    final photoStatus =
        await s.photos.captioner?.status() ?? PhotoModelStatus.unsupported;
    final hasPin = await s.settings.hasPasscode();
    final bio = await s.settings.biometricEnabled();
    final notifs = await s.settings.notificationsEnabled();
    final morning = await s.settings.nudgeMorning();
    final evening = await s.settings.nudgeEvening();
    final gate = s.cloudGate;
    final avail = gate == null ? false : await gate.anyProviderAvailable;
    final tier = await s.entitlements?.tier() ?? Tier.free;
    final feats = {
      for (final f in CloudFeature.values)
        f: await s.settings.cloudFeatureEnabled(f)
    };
    if (mounted) {
      setState(() {
        _keys = keys;
        _training = t;
        _photoModelStatus = photoStatus;
        _hasPasscode = hasPin;
        _biometric = bio;
        _notifications = notifs;
        _nudgeMorning = morning;
        _nudgeEvening = evening;
        _cloudAvailable = avail;
        _tier = tier;
        _features
          ..clear()
          ..addAll(feats);
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
            ListTile(
                title: Text(k.name, style: Theme.of(ctx).textTheme.titleLarge)),
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
                subtitle: const Text(
                    'Moves every entry and example, then archives this one'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final target = await _pickKey(exclude: k.id);
                  if (target == null) return;
                  await s.db.mergeKeys(fromKeyId: k.id, toKeyId: target.id);
                  await s.matcher.warmUp();
                  _load();
                }),
            ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive'),
                subtitle:
                    const Text('Hidden from chips and pickers; entries stay'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await s.db.updateKey(
                      k.id, const KeysCompanion(isArchived: Value(true)));
                  await s.matcher.warmUp();
                  _load();
                }),
          ]),
        ),
      ),
    );
  }

  Future<db.Key?> _pickKey({required int exclude}) =>
      showModalBottomSheet<db.Key>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final k in _keys.where((k) => k.id != exclude))
                ListTile(
                    title: Text(k.name), onTap: () => Navigator.pop(ctx, k))
            ],
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
        await s.db.updateKey(
            existing.id, const KeysCompanion(isArchived: Value(false)));
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
        content:
            TextField(controller: c, autofocus: true, obscureText: obscure),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(d, c.text.trim().toLowerCase()),
              child: const Text('Save')),
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
    if (!mounted) return;
    await _showExportFileActions(
        f, 'Encrypted backup ready', 'Keylire backup', 'keylire');
  }

  Future<void> _exportMarkdown() async {
    final s = ServicesScope.of(context);
    try {
      final f = await s.export.exportMarkdown();
      if (!mounted) return;
      await _showExportFileActions(f, 'Markdown log ready', 'Keylire log', 'md');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't export Markdown: $e")),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    final s = ServicesScope.of(context);
    try {
      final f = await s.export.exportCsv();
      if (!mounted) return;
      await _showExportFileActions(
          f, 'Spreadsheet ready', 'Keylire spreadsheet', 'csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't export CSV: $e")),
        );
      }
    }
  }

  Future<void> _showExportFileActions(
      File f, String sheetTitle, String dialogTitle, String ext) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Dl.of(context).x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(sheetTitle),
                subtitle: Text(p.basename(f.path)),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Save to device'),
                subtitle: const Text('Choose Downloads, Drive, or a folder'),
                onTap: () => Navigator.pop(sheetContext, 'save'),
              ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share file'),
                  subtitle: const Text('Send it with the system share sheet'),
                  onTap: () => Navigator.pop(sheetContext, 'share'),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == 'save') {
      final bytes = await f.readAsBytes();
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save $dialogTitle',
        fileName: p.basename(f.path),
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: bytes,
      );
      if (saved != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$sheetTitle saved')),
        );
      }
    } else if (action == 'share') {
      try {
        await BackupFileBridge.share(f);
      } on PlatformException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? "Couldn't share file")),
          );
        }
      }
    }
  }

  Future<void> _managePasscode() async {
    final s = ServicesScope.of(context);
    final hasPin = await s.settings.hasPasscode();
    if (!mounted) return;

    if (hasPin) {
      final current = await _ask('Current 4-digit PIN', '', obscure: true);
      if (current == null) return;
      final valid = await s.settings.verifyPasscode(current);
      if (!valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
        }
        return;
      }

      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (c) => SimpleDialog(
          title: const Text('Passcode Lock'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'change'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Change 4-digit PIN'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'remove'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Turn off passcode lock',
                    style: TextStyle(color: DlColors.danger)),
              ),
            ),
          ],
        ),
      );

      if (action == 'remove') {
        await s.settings.setPasscode(null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passcode lock removed')),
          );
        }
        _load();
      } else if (action == 'change') {
        final newPin = await _ask('Enter new 4-digit PIN', '', obscure: true);
        if (newPin == null ||
            newPin.length != 4 ||
            int.tryParse(newPin) == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN must be 4 digits')),
            );
          }
          return;
        }
        final confirmPin =
            await _ask('Confirm new 4-digit PIN', '', obscure: true);
        if (newPin != confirmPin) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PINs do not match')),
            );
          }
          return;
        }
        await s.settings.setPasscode(newPin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully')),
          );
        }
        _load();
      }
    } else {
      final newPin = await _ask('Create a 4-digit PIN', '', obscure: true);
      if (newPin == null ||
          newPin.length != 4 ||
          int.tryParse(newPin) == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN must be 4 digits')),
          );
        }
        return;
      }
      final confirmPin = await _ask('Confirm 4-digit PIN', '', obscure: true);
      if (newPin != confirmPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs do not match')),
          );
        }
        return;
      }
      await s.settings.setPasscode(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passcode lock enabled')),
        );
      }
      _load();
    }
  }

  Future<void> _restore() async {
    final s = ServicesScope.of(context);
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['keylire'],
    );
    final path = r?.files.single.path;
    if (path == null) return;
    final pass = await _ask('Passphrase', '', obscure: true);
    if (pass == null) return;
    try {
      await s.export.restoreEncrypted(File(path), pass);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Restored')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Couldn't restore: $e")));
      }
    }
  }

  Future<void> _exportCorrections() async {
    final s = ServicesScope.of(context);
    final rows = await s.db.allCorrections();
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln(jsonEncode({
        'in': r.rawText,
        'field': r.field,
        'predicted': r.predicted,
        'corrected': r.corrected
      }));
    }
    final dir = await getApplicationDocumentsDirectory();
    final f = File(p.join(dir.path, 'exports',
        'corrections-${DateTime.now().millisecondsSinceEpoch}.jsonl'));
    await f.parent.create(recursive: true);
    await f.writeAsString(buf.toString());
    await Clipboard.setData(ClipboardData(text: f.path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${rows.length} corrections — path copied')));
    }
  }

  Future<void> _deleteAllPhotos() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete all photos?'),
        content: const Text(
            'Entries stay. The image files are removed from this phone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    final dir = Directory(
        p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
    if (await dir.exists()) await dir.delete(recursive: true);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Photos deleted')));
    }
  }

  Future<void> _downloadPhotoModel() async {
    final services = ServicesScope.of(context);
    final captioner = services.photos.captioner;
    if (captioner == null || _photoModelBusy) return;
    setState(() => _photoModelBusy = true);
    try {
      await captioner.download();
      await services.settings.setPhotoModelPrompted(true);
      final status = await captioner.status();
      if (mounted) {
        setState(() => _photoModelStatus = status);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == PhotoModelStatus.available
              ? 'Better photo descriptions are ready'
              : 'Model download started. Keylire will use it when ready.'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't download the photo model: $error")),
        );
      }
    } finally {
      if (mounted) setState(() => _photoModelBusy = false);
    }
  }

  Future<void> _checkDatabaseHealth() async {
    final s = ServicesScope.of(context);
    final ok = await s.db.checkIntegrity();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Database healthy (PRAGMA integrity check passed).'
            : 'Warning: database integrity issues detected.'),
      ),
    );
  }

  Future<void> _cleanupSoftDeleted() async {
    final s = ServicesScope.of(context);
    final deleted = await s.db.cleanupSoftDeleted(daysOld: 30);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted > 0
            ? 'Purged $deleted old deleted records.'
            : 'No old records needed purging.'),
      ),
    );
  }

  Future<void> _byokSheet() async {
    final s = ServicesScope.of(context);
    final key = TextEditingController(text: await s.settings.apiKey() ?? '');
    final url = TextEditingController(text: await s.settings.cloudBaseUrl());
    final text = TextEditingController(text: await s.settings.cloudTextModel());
    final vision = TextEditingController(text: await s.settings.cloudVisionModel());
    if (!mounted) return;
    final dl = Dl.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(dl.x5, dl.x4, dl.x5, MediaQuery.viewInsetsOf(ctx).bottom + dl.x5),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Your own API key', style: Theme.of(ctx).textTheme.titleLarge),
            SizedBox(height: dl.x1),
            Text('Any OpenAI-compatible endpoint. The key is stored only on this phone and sent only to the URL below.',
                style: Theme.of(ctx).textTheme.bodySmall),
            SizedBox(height: dl.x3),
            TextField(controller: key, obscureText: true, decoration: const InputDecoration(labelText: 'API key')),
            TextField(controller: url, decoration: const InputDecoration(labelText: 'Chat completions URL')),
            TextField(controller: text, decoration: const InputDecoration(labelText: 'Text model')),
            TextField(controller: vision, decoration: const InputDecoration(labelText: 'Vision model')),
            SizedBox(height: dl.x4),
            Row(children: [
              TextButton(
                  onPressed: () async {
                    await s.settings.setApiKey(null);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Remove key')),
              const Spacer(),
              FilledButton(
                  onPressed: () async {
                    await s.settings.setApiKey(key.text);
                    await s.settings.setCloudBaseUrl(url.text);
                    await s.settings.setCloudTextModel(text.text);
                    await s.settings.setCloudVisionModel(vision.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save')),
            ]),
          ]),
        ),
      ),
    );
    _load();
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
        Text('About Keylire', style: theme.textTheme.titleSmall),
        _tile(
          Icons.menu_book_outlined,
          'How Keylire works',
          () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const HowToUseScreen(),
          )),
          sub: 'A quick guide to logging, keys, days, patterns, and privacy.',
        ),
        SizedBox(height: dl.x5),
        Text('Your keys', style: theme.textTheme.titleSmall),
        _tile(Icons.restaurant_outlined, 'Remembered meals',
          () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const SavedMealsScreen())),
          sub: 'Nutrition you saved, serving sizes, and meal names.'),
        Text('Keys are your own words for the things you do.',
            style: theme.textTheme.bodySmall),
        SizedBox(height: dl.x2),
        Wrap(spacing: dl.x2, runSpacing: dl.x2, children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('New key'),
            onPressed: _createKey,
          ),
          for (final k in _keys)
            ActionChip(label: Text(k.name), onPressed: () => _keySheet(k)),
        ]),
        SizedBox(height: dl.x6),
        Text('Learning', style: theme.textTheme.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Confirm every key for two weeks'),
          subtitle: const Text(
              'Nothing files itself until you\'ve taught it. Turn off when it feels right.'),
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
        SizedBox(height: dl.x6),
        Text('Reminders', style: theme.textTheme.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me of planned entries'),
          subtitle:
              const Text('A notification at the time, with Done and Skip.'),
          value: _notifications,
          onChanged: (v) async {
            if (v) {
              final ok = await s.reminders?.requestPermission() ?? false;
              if (!ok) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Notifications are blocked in system settings')));
                }
                return;
              }
            }
            await s.settings.setNotificationsEnabled(v);
            s.reminders?.sync();
            _load();
          },
        ),
        if (_notifications) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Morning digest'),
            subtitle: const Text(
                'Today\'s plans, shortly after your usual wake time.'),
            value: _nudgeMorning,
            onChanged: (v) async {
              await s.settings.setNudgeMorning(v);
              s.reminders?.sync();
              _load();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Evening check-in'),
            subtitle: const Text('An hour before bed, only on quiet days.'),
            value: _nudgeEvening,
            onChanged: (v) async {
              await s.settings.setNudgeEvening(v);
              s.reminders?.sync();
              _load();
            },
          ),
        ],
        SizedBox(height: dl.x6),
        Text('On-device intelligence', style: theme.textTheme.titleSmall),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.image_search_outlined),
          title: Text('Photo recognition included'),
          subtitle: Text(
            'Keylire can read text and recognize common objects immediately, offline, on every supported phone.',
          ),
          trailing: Icon(Icons.check, size: 20),
        ),
        if (_photoModelStatus != PhotoModelStatus.unsupported)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _photoModelBusy ||
                    _photoModelStatus == PhotoModelStatus.downloading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_photoModelStatus == PhotoModelStatus.available
                    ? Icons.auto_awesome
                    : Icons.download_outlined),
            title: Text(_photoModelStatus == PhotoModelStatus.available
                ? 'Better photo descriptions ready'
                : 'Download better photo understanding'),
            subtitle: const Text(
              'Uses Gemini Nano on supported phones. The model downloads once; photos stay on this device.',
            ),
            trailing: _photoModelStatus == PhotoModelStatus.available
                ? const Icon(Icons.check, size: 20)
                : TextButton(
                    onPressed: _photoModelBusy ? null : _downloadPhotoModel,
                    child: const Text('Download'),
                  ),
          ),
        SizedBox(height: dl.x6),
        Text('Cloud assistance', style: theme.textTheme.titleSmall),
        Text(
          _tier == Tier.premium
              ? 'Keylire Premium is active. Requests go through Keylire\'s servers; your logbook stays on this phone.'
              : 'Off by default. Turn on a feature below and add your own API key, or upgrade to Premium.',
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: dl.x2),
        for (final f in CloudFeature.values)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.label),
            subtitle: Text('Sends ${f.sends}.'),
            value: _features[f] ?? false,
            onChanged: (v) async {
              await s.settings.setCloudFeatureEnabled(f, v);
              _load();
            },
          ),
        if (_features.values.any((v) => v) && !_cloudAvailable)
          Padding(
            padding: EdgeInsets.only(top: dl.x1),
            child: Text(
              'Nothing will be sent until you add a key or upgrade.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        _tile(Icons.vpn_key_outlined, 'Use your own API key', _byokSheet,
            sub: 'Free. Groq, OpenAI, OpenRouter or any compatible endpoint.'),
        if (_tier != Tier.premium)
          _tile(Icons.workspace_premium_outlined, 'Keylire Premium', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium purchases arrive in a later build')));
          }, sub: 'No key to manage. Photo reading, note splitting, summaries and insights.'),
        SizedBox(height: dl.x6),
        Text('Privacy', style: theme.textTheme.titleSmall),
        Text(
            'Keylire matching, summaries, and photo recognition run on this phone. '
            'Voice transcription uses your phone\'s speech service and follows its privacy settings. '
            'Keylire has no account and does not upload your journal.',
            style: theme.textTheme.bodyMedium),
        SizedBox(height: dl.x2),
        _tile(
          _hasPasscode ? Icons.pin_drop : Icons.lock_outline,
          _hasPasscode ? 'App passcode lock active' : 'Set app passcode lock',
          _managePasscode,
          sub: _hasPasscode
              ? '4-digit PIN is required to open Keylire. Tap to change or remove.'
              : 'Lock your personal logbook with a 4-digit PIN.',
        ),
        if (_hasPasscode)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Unlock with fingerprint or face'),
            subtitle: const Text('PIN still works as a fallback.'),
            value: _biometric,
            onChanged: (v) async {
              await s.settings.setBiometricEnabled(v);
              _load();
            },
          ),
        _tile(Icons.hide_image_outlined, 'Delete all photos', _deleteAllPhotos),
        SizedBox(height: dl.x6),
        Text('Backup & Data Portability', style: theme.textTheme.titleSmall),
        _tile(
            Icons.lock_outline, 'Create or share an encrypted backup', _export,
            sub:
                'Save a .keylire file to Downloads or Drive, or send it with the share sheet. Fully restores your setup and history.'),
        _tile(Icons.restore, 'Restore from a backup', _restore),
        _tile(Icons.description_outlined, 'Export as Markdown (.md)',
            _exportMarkdown,
            sub:
                'Export all events as readable markdown for Obsidian, Notion, or text editors.'),
        _tile(Icons.table_chart_outlined, 'Export as Spreadsheet (.csv)',
            _exportCsv,
            sub:
                'Export all events with dates, keys, durations, and notes as a spreadsheet.'),
        SizedBox(height: dl.x6),
        Text('Storage & Maintenance', style: theme.textTheme.titleSmall),
        _tile(Icons.health_and_safety_outlined, 'Check database integrity',
            _checkDatabaseHealth,
            sub: 'Runs SQLite integrity check on local database file.'),
        _tile(Icons.cleaning_services_outlined, 'Purge old deleted records',
            _cleanupSoftDeleted,
            sub: 'Permanently removes soft-deleted events older than 30 days.'),
        SizedBox(height: dl.x6),
        InkWell(
          onTap: () => setState(() => _dev = !_dev),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dl.x2),
            child: Text('Keylire 0.2 · local-first',
                style: theme.textTheme.bodySmall),
          ),
        ),
        if (_dev) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dev: pretend Premium'),
            value: _tier == Tier.premium,
            onChanged: (v) async {
              final e = s.entitlements;
              if (e is LocalEntitlements) await e.setOverride(v);
              _load();
            },
          ),
          _tile(Icons.download_outlined, 'Export corrections (jsonl)',
              _exportCorrections,
              sub:
                  'Every time you fixed a key or a time. Feeds the phrase corpus.'),
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
              String f(num? x, [int d = 1]) =>
                  x == null ? '—' : x.toStringAsFixed(d);
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
