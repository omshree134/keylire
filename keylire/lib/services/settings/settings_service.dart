import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../data/db/database.dart';
import '../cloud/cloud_provider.dart';

/// Typed access over the settings table.
///
/// Privacy rules enforced here, not in the UI:
///   - No API key  => nothing ever leaves the device, whatever the toggles say.
///   - Text analysis and photo upload are SEPARATE toggles, both default OFF.
///   - The key only ever comes from the user (Settings screen). Nothing in the
///     build or the source can supply one.
class SettingsService {
  SettingsService(this.db);
  final AppDatabase db;

  // ------------------------------------------------------------ cloud AI
  //
  // Rules, enforced here not in the UI:
  //   - Every cloud feature is a separate toggle, default OFF.
  //   - BYOK: no key => nothing leaves the device regardless of toggles.
  //   - Hosted: no entitlement => same.

  static const _defaultBaseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _defaultTextModel = 'llama-3.3-70b-versatile';
  static const _defaultVisionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  Future<String?> apiKey() async {
    final k = await db.setting('cloud_api_key');
    if (k != null && k.trim().isNotEmpty) return k.trim();
    return null;
  }

  Future<bool> hasApiKey() async => (await apiKey()) != null;
  Future<void> setApiKey(String? v) => db.putSetting('cloud_api_key', (v ?? '').trim());

  Future<String> cloudBaseUrl() async =>
      (await db.setting('cloud_base_url'))?.trim().ifEmpty ?? _defaultBaseUrl;
  Future<void> setCloudBaseUrl(String? v) => db.putSetting('cloud_base_url', (v ?? '').trim());

  Future<String> cloudTextModel() async =>
      (await db.setting('cloud_text_model'))?.trim().ifEmpty ?? _defaultTextModel;
  Future<void> setCloudTextModel(String? v) => db.putSetting('cloud_text_model', (v ?? '').trim());

  Future<String> cloudVisionModel() async =>
      (await db.setting('cloud_vision_model'))?.trim().ifEmpty ?? _defaultVisionModel;
  Future<void> setCloudVisionModel(String? v) => db.putSetting('cloud_vision_model', (v ?? '').trim());

  Future<bool> cloudFeatureEnabled(CloudFeature f) async =>
      (await db.setting(f.settingKey)) == 'true';
  Future<void> setCloudFeatureEnabled(CloudFeature f, bool v) =>
      db.putSetting(f.settingKey, '$v');

  /// Kept for DayCloseService's old call site; prefer CloudGate.
  Future<bool> llmTextEnabled() => cloudFeatureEnabled(CloudFeature.dayClose);

  /// One-time: carry a key saved under the old name forward, and map the
  /// old global toggles onto the new per-feature ones.
  Future<void> migrateLegacyCloudSettings() async {
    final old = await db.setting('groq_api_key');
    if (old != null && old.isNotEmpty && (await db.setting('cloud_api_key')) == null) {
      await db.putSetting('cloud_api_key', old);
    }
    await db.putSetting('groq_api_key', '');
    if ((await db.setting('llm_text_enabled')) == 'true') {
      await setCloudFeatureEnabled(CloudFeature.dayClose, true);
    }
    if ((await db.setting('photo_cloud_enabled')) == 'true') {
      await setCloudFeatureEnabled(CloudFeature.photoExtract, true);
    }
    await db.putSetting('llm_text_enabled', 'false');
    await db.putSetting('photo_cloud_enabled', 'false');
  }

  Future<bool> photoModelPrompted() async =>
      (await db.setting('photo_model_prompted')) == 'true';

  Future<void> setPhotoModelPrompted(bool value) =>
      db.putSetting('photo_model_prompted', '$value');

  Future<bool> hasSeenHowTo() async =>
      (await db.setting('how_to_seen')) == 'true';

  Future<void> setHowToSeen(bool value) =>
      db.putSetting('how_to_seen', '$value');

  // ------------------------------------------------------------ embedder

  /// Which embedding model produced the vectors currently in key_examples.
  /// Empty on a fresh install.
  Future<String> embedderId() async => (await db.setting('embedder_id')) ?? '';

  Future<void> setEmbedderId(String id) => db.putSetting('embedder_id', id);

  Future<void> setSleepEveningHour(int h) =>
      db.putSetting('sleep_evening_hour', '$h');
  Future<void> setDayCutoffHour(int h) =>
      db.putSetting('day_cutoff_hour', '$h');

  Future<bool> notificationsEnabled() async =>
      (await db.setting('notifications_enabled')) == 'true';
  Future<void> setNotificationsEnabled(bool v) =>
      db.putSetting('notifications_enabled', '$v');

  // ------------------------------------------------------------ day logic

  Future<int> dayCutoffHour() async =>
      int.tryParse(await db.setting('day_cutoff_hour') ?? '') ?? 4;

  Future<int> sleepEveningHour() async =>
      int.tryParse(await db.setting('sleep_evening_hour') ?? '') ?? 20;

  Future<double> autoAssignThreshold() async =>
      double.tryParse(await db.setting('auto_assign_threshold') ?? '') ??
      0.72; // MiniLM cosine; 0.85 was a centroid-era number

  Future<double> pickerThreshold() async =>
      double.tryParse(await db.setting('picker_threshold') ?? '') ?? 0.45;

  Future<bool> inTrainingMode() async {
    final until = await db.setting('training_mode_until');
    if (until == null || until.isEmpty) return false;
    final dt = DateTime.tryParse(until);
    return dt != null && DateTime.now().isBefore(dt);
  }

  Future<void> startTrainingMode({int days = 14}) => db.putSetting(
      'training_mode_until',
      DateTime.now().add(Duration(days: days)).toIso8601String());

  // ------------------------------------------------ LLM budget (hard cap)

  Future<int> monthlyBudgetUsdCents() async =>
      int.tryParse(await db.setting('monthly_budget_usd_cents') ?? '') ?? 300;

  Future<int> spentThisMonthMicrocents() async {
    final month = _thisMonth();
    if ((await db.setting('budget_month')) != month) {
      await db.putSetting('budget_month', month);
      await db.putSetting('budget_spent_usd_microcents', '0');
      return 0;
    }
    return int.tryParse(
            await db.setting('budget_spent_usd_microcents') ?? '') ??
        0;
  }

  Future<void> addSpendMicrocents(int microcents) async {
    final current = await spentThisMonthMicrocents();
    await db.putSetting(
        'budget_spent_usd_microcents', '${current + microcents}');
  }

  Future<bool> budgetExceeded() async =>
      (await spentThisMonthMicrocents()) >=
      (await monthlyBudgetUsdCents()) * 1000000;

  static String _thisMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------ app lock

  Future<bool> hasPasscode() async {
    final hash = await db.setting('app_lock_hash');
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPasscode(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await db.putSetting('app_lock_hash', '');
      await db.putSetting('app_lock_salt', '');
      return;
    }
    final rnd = SecureRandom.fast;
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final saltHex = salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final bytes = utf8.encode('$pin:$saltHex');
    final hashObj = await Sha256().hash(bytes);
    final hashHex =
        hashObj.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await db.putSetting('app_lock_salt', saltHex);
    await db.putSetting('app_lock_hash', hashHex);
  }

  Future<bool> verifyPasscode(String pin) async {
    final saltHex = await db.setting('app_lock_salt');
    final expectedHash = await db.setting('app_lock_hash');
    if (saltHex == null || expectedHash == null || expectedHash.isEmpty) {
      return true;
    }
    final bytes = utf8.encode('$pin:$saltHex');
    final hashObj = await Sha256().hash(bytes);
    final hashHex =
        hashObj.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return hashHex == expectedHash;
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}
