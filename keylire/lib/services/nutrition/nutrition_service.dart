import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import '../../data/db/database.dart';

/// Small, local meal memories. Values are per serving, never inferred from pixels.
class NutritionService {
  NutritionService(this.db);
  final AppDatabase db;
  static const prefix = 'meal_memory_';
  static const nutrients = ['calories', 'protein', 'carbs', 'fat'];

  static Map<String, dynamic> metadata(String? value) {
    try {
      return value == null
          ? {}
          : Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      return {};
    }
  }

  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<List<Map<String, dynamic>>> meals() async {
    final rows = await db
        .customSelect(
          "SELECT k, v FROM settings WHERE k LIKE 'meal_memory_%' ORDER BY k",
        )
        .get();
    return rows
        .map((r) => metadata(r.read<String>('v')))
        .where((m) => m['name'] is String && m['values'] is Map)
        .toList();
  }

  Future<void> forget(String id) =>
      db.customStatement('DELETE FROM settings WHERE k = ?', ['$prefix$id']);

  Future<void> remember(
      {required String name,
      required List<String> aliases,
      required Map<String, double> totals,
      required double servings,
      List<double>? signature}) async {
    if (normalize(name).isEmpty ||
        servings <= 0 ||
        !servings.isFinite ||
        totals.isEmpty ||
        totals.entries.any((e) =>
            !nutrients.contains(e.key) || !e.value.isFinite || e.value < 0)) {
      throw ArgumentError('Enter a meal name, serving count and nutrients.');
    }
    final id = base64Url.encode(utf8.encode(normalize(name)));
    final existing = metadata(await db.setting('$prefix$id'));
    await db.putSetting(
        '$prefix$id',
        jsonEncode({
          'id': id,
          'name': name.trim(),
          'aliases': {normalize(name), ...aliases.map(normalize)}
              .where((a) => a.isNotEmpty)
              .toList(),
          'values': {for (final e in totals.entries) e.key: e.value / servings},
          'signature': signature ?? existing['signature'],
        }));
  }

  /// Deliberately exact: "my oats" or "2 servings of my oats", not "oats cake".
  Future<Map<String, dynamic>?> matchText(String text) async {
    var query = text.toLowerCase().trim();
    query = query.replaceFirst(RegExp(r'^(?:add|log|ate|had|eat)\s+'), '');
    final savedMeals = await meals();
    final exact = savedMeals
        .where((m) => (m['aliases'] as List).contains(normalize(query)))
        .toList();
    if (exact.length > 1) return null;
    if (exact.length == 1) return valuesFor(exact.single, 1);
    double servings = 1;
    final count = RegExp(
            r'^(\d+(?:\.\d+)?)\s+(?:(?:servings?|portions?)\s+(?:of\s+)?)?(.+)$')
        .firstMatch(query);
    if (count != null) {
      servings = double.parse(count[1]!);
      query = count[2]!;
    }
    if (servings <= 0 || !servings.isFinite) return null;
    final matches = savedMeals
        .where((m) => (m['aliases'] as List).contains(normalize(query)))
        .toList();
    if (matches.length != 1) return null;
    return valuesFor(matches.single, servings);
  }

  static Map<String, dynamic> valuesFor(
          Map<String, dynamic> meal, double servings) =>
      {
        for (final e in (meal['values'] as Map).entries)
          e.key as String: (e.value as num).toDouble() * servings,
        'nutrition_servings': servings,
        'nutrition_source': 'remembered',
        'meal_name': meal['name'],
        'meal_id': meal['id'],
      };

  /// A 192-number visual signature, not a neural model. Suggestions only:
  /// similar appearance cannot establish ingredients, weight or nutrition.
  static Future<List<double>?> signature(File file) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(await file.readAsBytes(),
          targetWidth: 8, targetHeight: 8);
      image = (await codec.getNextFrame()).image;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) return null;
      return [
        for (var i = 0; i < bytes.lengthInBytes; i++)
          if (i % 4 != 3) bytes.getUint8(i) / 255
      ];
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  Future<Map<String, dynamic>?> suggestPhoto(List<double> signature) async {
    final ranked = <({double distance, Map<String, dynamic> meal})>[];
    for (final meal in await meals()) {
      final saved = meal['signature'];
      if (saved is! List || saved.length != signature.length) continue;
      double distance = 0;
      for (var i = 0; i < signature.length; i++) {
        final delta = signature[i] - (saved[i] as num).toDouble();
        distance += delta * delta;
      }
      ranked.add((distance: distance / signature.length, meal: meal));
    }
    ranked.sort((a, b) => a.distance.compareTo(b.distance));
    if (ranked.isEmpty || ranked.first.distance > 0.015) return null;
    if (ranked.length > 1 && ranked[1].distance - ranked[0].distance < 0.005) {
      return null;
    }
    return ranked.first.meal;
  }
}
