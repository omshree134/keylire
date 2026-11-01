import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keylire/data/db/database.dart';
import 'package:keylire/services/nutrition/nutrition_service.dart';
import 'package:keylire/services/backup/export_service.dart';
import 'package:keylire/services/capture/capture_service.dart';
import 'package:keylire/services/embeddings/hashing_embedding_service.dart';
import 'package:keylire/services/matching/key_matcher.dart';
import 'package:keylire/services/settings/settings_service.dart';
import 'package:keylire/services/time/time_vocab_service.dart';

void main() {
  late AppDatabase db;
  late NutritionService nutrition;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    nutrition = NutritionService(db);
  });
  tearDown(() => db.close());

  Future<void> oats() => nutrition.remember(
      name: 'My oats',
      aliases: ['usual breakfast'],
      totals: {'calories': 600, 'protein': 30},
      servings: 2,
      signature: List.filled(192, 0.5));

  test('meal totals normalize per serving and explicit portions scale',
      () async {
    await oats();
    final result = await nutrition.matchText('Log 2.5 servings of my oats');
    expect(result!['calories'], 750);
    expect(result['protein'], 37.5);
    expect(result.containsKey('fat'), false); // unknown is not zero
    expect((await nutrition.matchText('usual breakfast'))!['calories'], 300);
    expect(await nutrition.matchText('my oats cake'), isNull);
    expect(await nutrition.matchText('0 servings of my oats'), isNull);
  });

  test('ambiguous names never auto-apply and replacements persist', () async {
    await oats();
    await nutrition.remember(
        name: 'Other breakfast',
        aliases: ['usual breakfast'],
        totals: {'calories': 200},
        servings: 1);
    expect(await nutrition.matchText('usual breakfast'), isNull);
    await nutrition.remember(
        name: 'My oats', aliases: [], totals: {'protein': 20}, servings: 1);
    final freshService = NutritionService(db);
    final meal = await freshService.matchText('my oats');
    expect(meal!['protein'], 20);
    expect(meal.containsKey('calories'), false);
    await nutrition.forget(meal['meal_id'] as String);
    expect(await nutrition.matchText('my oats'), isNull);
  });

  test('invalid nutrient values and meaningless meal names are rejected',
      () async {
    for (final value in [-1.0, double.nan, double.infinity]) {
      await expectLater(
          nutrition.remember(
              name: 'Oats',
              aliases: [],
              totals: {'calories': value},
              servings: 1),
          throwsArgumentError);
    }
    await expectLater(
        nutrition.remember(
            name: '!!!', aliases: [], totals: {'calories': 200}, servings: 1),
        throwsArgumentError);
  });

  test(
      'photo similarity offers a candidate, rejects distant and ambiguous examples',
      () async {
    await oats();
    expect((await nutrition.suggestPhoto(List.filled(192, 0.5)))!['name'],
        'My oats');
    expect(await nutrition.suggestPhoto(List.filled(192, 0.9)), isNull);
    await nutrition.remember(
        name: 'Rice',
        aliases: [],
        totals: {'calories': 100},
        servings: 1,
        signature: List.filled(192, 0.5));
    expect(await nutrition.suggestPhoto(List.filled(192, 0.5)), isNull);
  });

  test('remembered text flows through capture with scaled nutrients', () async {
    await oats();
    final settings = SettingsService(db);
    final matcher = KeyMatcher(db, HashingEmbeddingService(), settings);
    final capture = CaptureService(db, matcher, settings, TimeVocabService(db));
    final foodKey = await db.createKey('food');
    await capture.capture(
        rawText: 'add 2 servings of my oats',
        modality: 'text',
        forcedKeyId: foodKey);
    final events = await db.select(db.events).get();
    final meta = NutritionService.metadata(events.single.metadata);
    expect(meta['calories'], 600);
    expect(meta['protein'], 30);
    expect(meta['nutrition_source'], 'remembered');
  });

  test('meal memories survive the backup settings restore path', () async {
    await oats();
    final settingsRows = await db.customSelect('SELECT * FROM settings').get();
    final backup = jsonEncode({
      'format': 'keylire-export',
      'tables': {'settings': settingsRows.map((r) => r.data).toList()}
    });
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await ExportService(other).restoreFromJson(backup);
      expect(
          (await NutritionService(other).matchText('my oats'))!['protein'], 15);
    } finally {
      await other.close();
    }
  });
}
