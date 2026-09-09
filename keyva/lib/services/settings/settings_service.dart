import '../../data/db/database.dart';

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

  Future<String?> apiKey() async {
    final g = await db.setting('groq_api_key');
    if (g != null && g.trim().isNotEmpty) return g.trim();
    return null;
  }

  Future<bool> hasApiKey() async => (await apiKey()) != null;

  Future<void> setApiKey(String? v) =>
      db.putSetting('groq_api_key', (v ?? '').trim());

  /// True only if the user has BOTH entered a key AND turned this on.
  Future<bool> llmTextEnabled() async {
    if (!await hasApiKey()) return false;
    return (await db.setting('llm_text_enabled')) == 'true';
  }

  Future<bool> photoCloudEnabled() async {
    if (!await hasApiKey()) return false;
    return (await db.setting('photo_cloud_enabled')) == 'true';
  }

  Future<void> setLlmTextEnabled(bool v) =>
      db.putSetting('llm_text_enabled', '$v');

  Future<void> setPhotoCloudEnabled(bool v) =>
      db.putSetting('photo_cloud_enabled', '$v');

  // ------------------------------------------------------------ embedder

  /// Which embedding model produced the vectors currently in key_examples.
  /// Empty on a fresh install.
  Future<String> embedderId() async => (await db.setting('embedder_id')) ?? '';

  Future<void> setEmbedderId(String id) => db.putSetting('embedder_id', id);

  Future<void> setSleepEveningHour(int h) => db.putSetting('sleep_evening_hour', '$h');
  Future<void> setDayCutoffHour(int h) => db.putSetting('day_cutoff_hour', '$h');

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
      double.tryParse(await db.setting('auto_assign_threshold') ?? '') ?? 0.72; // MiniLM cosine; 0.85 was a centroid-era number

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
}
