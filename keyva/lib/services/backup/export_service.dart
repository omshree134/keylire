import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/db/database.dart';

/// Phase-1 backup: SQLite on one phone is one dropped phone from total loss.
///
/// Exports a full JSON dump of every table, encrypted with AES-256-GCM using
/// a key derived from the user's passphrase (PBKDF2, 150k rounds). Output is
/// a single .keyva file the user shares/stores wherever they like.
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
    final file = File(p.join(dir.path, 'exports', 'keyva-$stamp.keyva'));
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

  Future<void> restoreFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data is! Map || data['format'] != 'keyva-export') {
      throw const FormatException('Invalid Keyva backup file format');
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
  }

  Future<Map<String, dynamic>> _dumpAll() async {
    Future<List<Map<String, dynamic>>> rows(String table) async {
      final res = await db.customSelect('SELECT * FROM $table').get();
      return res.map((r) => r.data).toList();
    }

    return {
      'format': 'keyva-export',
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
