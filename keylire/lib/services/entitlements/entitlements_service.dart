import '../../data/db/database.dart';

enum Tier { free, premium }

abstract class EntitlementsService {
  Future<Tier> tier();

  /// Bearer token for HostedProvider. Null when not premium.
  Future<String?> hostedToken();

  /// Re-check with the store / your backend. Called on 401 and app resume.
  Future<void> refresh();
}

/// Settings-backed stub. `premium_override=true` (dev section in Settings)
/// turns Premium on for testing; `hosted_token` is whatever your proxy
/// hands out. Replace with a purchases_flutter implementation when you
/// wire IAP: tier() reads the active entitlement, hostedToken() exchanges
/// the RevenueCat app user id for a short-lived JWT from your backend.
class LocalEntitlements implements EntitlementsService {
  LocalEntitlements(this.db);
  final AppDatabase db;

  @override
  Future<Tier> tier() async =>
      (await db.setting('premium_override')) == 'true' ? Tier.premium : Tier.free;

  @override
  Future<String?> hostedToken() async {
    if (await tier() != Tier.premium) return null;
    final t = await db.setting('hosted_token');
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Future<void> refresh() async {}

  // dev helpers
  Future<void> setOverride(bool on) => db.putSetting('premium_override', '$on');
  Future<void> setToken(String? t) => db.putSetting('hosted_token', t ?? '');
}

