import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show OrderingTerm, Variable;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/db/database.dart';

/// Phase-1 backup: SQLite on one phone is one dropped phone from total loss.
///
/// Exports a full JSON dump of every table, encrypted with AES-256-GCM using
/// a key derived from the user's passphrase (PBKDF2, 150k rounds). Output is
/// a single .keylire file the user shares/stores wherever they like.
/// File layout: [16-byte salt][12-byte nonce][ciphertext][16-byte MAC].
class ExportService {
  ExportService(this.db);
  final AppDatabase db;

  static const _rounds = 150000;

  Future<File> exportEncrypted(String passphrase) async {
    final dump = jsonEncode(
      await _dumpAll(),
      toEncodable: (obj) {
        if (obj is Uint8List) return base64Encode(obj);
        if (obj is DateTime) return obj.toIso8601String();
        return obj.toString();
      },
    );

    final salt = _randomBytes(16);
    final secret = await _deriveKey(passphrase, salt);
    final algo = AesGcm.with256bits();
    final nonce = _randomBytes(12);
    final box = await algo.encrypt(utf8.encode(dump),
        secretKey: secret, nonce: nonce);

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'exports', 'keylire-$stamp.keylire'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(
        [...salt, ...nonce, ...box.cipherText, ...box.mac.bytes]);
    return file;
  }

  Future<String> importEncrypted(File file, String passphrase) async {
    final bytes = await file.readAsBytes();
    final salt = bytes.sublist(0, 16);
    final nonce = bytes.sublist(16, 28);
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final cipher = bytes.sublist(28, bytes.length - 16);

    final secret = await _deriveKey(passphrase, salt);
    final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipher, nonce: nonce, mac: mac),
        secretKey: secret);
    return utf8.decode(clear); // caller applies via a restore routine
  }

  Future<void> restoreEncrypted(File file, String passphrase) async {
    final jsonStr = await importEncrypted(file, passphrase);
    await restoreFromJson(jsonStr);
  }

  /// Exports all non-deleted events as clean, readable Markdown.
  Future<File> exportMarkdown() async {
    final keys = await db.activeKeys();
    final names = {for (final k in keys) k.id: k.name};
    final events = await (db.select(db.events)
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([
            (e) => OrderingTerm.desc(e.dayDate),
            (e) => OrderingTerm.asc(e.tsUtc),
          ]))
        .get();

    final buffer = StringBuffer();
    buffer.writeln('# Keylire Life Log Export');
    buffer.writeln('Exported on ${DateTime.now().toLocal()}\n');

    String? currentDay;
    for (final e in events) {
      if (e.dayDate != currentDay) {
        currentDay = e.dayDate;
        buffer.writeln('\n## $currentDay');
      }
      final local = e.tsUtc.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      final keyName = e.keyId != null ? '[${names[e.keyId] ?? '?'}] ' : '';

      final numParts = <String>[];
      if (e.durationMin != null) numParts.add('${e.durationMin} min');
      if (e.quantity != null) {
        final q = e.quantity!;
        final qStr = q == q.roundToDouble() ? '${q.toInt()}' : q.toStringAsFixed(1);
        numParts.add('$qStr ${e.unit ?? ''}'.trim());
      }
      final nums = numParts.isNotEmpty ? ' (${numParts.join(' · ')})' : '';
      final status = e.status == 'planned'
          ? ' *(planned)*'
          : (e.status == 'skipped' ? ' *(skipped)*' : '');

      buffer.writeln('- $hh:$mm $keyName${e.rawText}$nums$status');
      if (e.note != null && e.note!.trim().isNotEmpty) {
        buffer.writeln('  > ${e.note!.trim().replaceAll('\n', '\n  > ')}');
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'exports', 'keylire-log-$stamp.md'));
    await file.parent.create(recursive: true);
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Exports all non-deleted events as spreadsheet-ready CSV.
  Future<File> exportCsv() async {
    final keys = await db.activeKeys();
    final names = {for (final k in keys) k.id: k.name};
    final events = await (db.select(db.events)
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([
            (e) => OrderingTerm.desc(e.dayDate),
            (e) => OrderingTerm.asc(e.tsUtc),
          ]))
        .get();

    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Key,Event,Duration_Min,Quantity,Unit,Note,Modality,Status');

    String escapeCsv(String? text) {
      if (text == null) return '';
      if (text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r')) {
        return '"${text.replaceAll('"', '""')}"';
      }
      return text;
    }

    for (final e in events) {
      final local = e.tsUtc.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      final keyName = e.keyId != null ? (names[e.keyId] ?? '') : '';

      buffer.writeln([
        e.dayDate,
        '$hh:$mm',
        escapeCsv(keyName),
        escapeCsv(e.rawText),
        e.durationMin?.toString() ?? '',
        e.quantity?.toString() ?? '',
        escapeCsv(e.unit),
        escapeCsv(e.note),
        e.modality,
        e.status,
      ].join(','));
    }

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'exports', 'keylire-data-$stamp.csv'));
    await file.parent.create(recursive: true);
    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<void> restoreFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data is! Map || data['format'] != 'keylire-export') {
      throw const FormatException('Invalid Keylire backup file format');
    }

    final tables = (data['tables'] as Map<String, dynamic>?) ?? {};

    const tableNames = [
      'list_items',
      'corrections',
      'events',
      'key_examples',
      'key_analyses',
      'day_summaries',
      'period_summaries',
      'recurrences',
      'recurrence_suppressions',
      'future_entries',
      'plans',
      'keys',
      'settings',
    ];

    const insertOrder = [
      'keys',
      'settings',
      'events',
      'list_items',
      'corrections',
      'key_examples',
      'day_summaries',
      'key_analyses',
      'period_summaries',
      'recurrences',
      'recurrence_suppressions',
      'future_entries',
      'plans',
    ];

    final allowedTables = tableNames.toSet();
    final validColPattern = RegExp(r'^[a-z0-9_]+$');

    // PRAGMA foreign_keys cannot be changed inside a transaction in SQLite
    await db.customStatement('PRAGMA foreign_keys = OFF');

    try {
      await db.transaction(() async {
        for (final t in tableNames) {
          await db.customStatement('DELETE FROM $t');
        }

        // Re-insert table by table in dependency order
        for (final tableName in insertOrder) {
          if (!tables.containsKey(tableName)) continue;
          final rows = tables[tableName] as List<dynamic>?;
          if (rows == null) continue;

          for (final row in rows) {
            if (row is! Map<String, dynamic>) continue;
            final cols = <String>[];
            final vars = <Variable>[];

            for (final col in row.entries) {
              if (!validColPattern.hasMatch(col.key)) continue;
              cols.add(col.key);
              final val = col.value;

              if (val == null) {
                vars.add(const Variable(null));
              } else if ((col.key == 'vector') && val is String) {
                // Decode base64 vector back to bytes
                vars.add(Variable<Uint8List>(base64Decode(val)));
              } else if (val is int) {
                vars.add(Variable.withInt(val));
              } else if (val is double) {
                vars.add(Variable.withReal(val));
              } else if (val is bool) {
                vars.add(Variable.withBool(val));
              } else {
                vars.add(Variable.withString(val.toString()));
              }
            }

            if (cols.isNotEmpty && allowedTables.contains(tableName)) {
              final placeholders = List.filled(cols.length, '?').join(', ');
              final colNames = cols.join(', ');
              await db.customInsert(
                'INSERT INTO $tableName ($colNames) VALUES ($placeholders)',
                variables: vars,
              );
            }
          }
        }
      });
    } finally {
      await db.customStatement('PRAGMA foreign_keys = ON');
    }
    await db.rebuildSearchIndex();
  }

  Future<Map<String, dynamic>> _dumpAll() async {
    Future<List<Map<String, dynamic>>> rows(String table) async {
      final res = await db.customSelect('SELECT * FROM $table').get();
      return res.map((r) => r.data).toList();
    }

    return {
      'format': 'keylire-export',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tables': {
        for (final t in [
          'keys',
          'events',
          'list_items',
          'corrections',
          'key_examples',
          'day_summaries',
          'key_analyses',
          'period_summaries',
          'recurrences',
          'recurrence_suppressions',
          'future_entries',
          'plans',
          'settings',
        ])
          t: await rows(t),
      },
    };
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _rounds,
      bits: 256,
    );
    return kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static List<int> _randomBytes(int n) {
    final rnd = SecureRandom.fast;
    return List<int>.generate(n, (_) => rnd.nextInt(256));
  }
}
