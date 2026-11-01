import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../data/db/database.dart';
import 'entitlements_service.dart';

/// Production entitlements. RevenueCat answers "is this person premium";
/// the Worker's /v1/token turns the RevenueCat app user id into a bearer
/// token HostedProvider can use. Tokens are cached in settings with their
/// expiry so a normal launch makes zero network calls.
class RevenueCatEntitlements implements EntitlementsService {
  RevenueCatEntitlements(this.db, {
    required this.tokenEndpoint, // '$hostedBaseUrl/v1/token'
    required this.entitlementId,
    http.Client? client,
  }) : _client = client;

  final AppDatabase db;
  final String tokenEndpoint;
  final String entitlementId;
  final http.Client? _client;

  bool _configured = false;

  /// Call once at startup. Anonymous app user ids are fine; RevenueCat
  /// persists them on-device and restores purchases by store account.
  Future<void> configure({required String androidKey, required String iosKey}) async {
    if (_configured) return;
    final key = Platform.isIOS ? iosKey : androidKey;
    if (key.isEmpty) return;
    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(key));
    _configured = true;
  }

  @override
  Future<Tier> tier() async {
    if (!_configured) return Tier.free;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlementId) ? Tier.premium : Tier.free;
    } catch (_) {
      return Tier.free;
    }
  }

  @override
  Future<String?> hostedToken() async {
    final cached = await db.setting('hosted_token');
    final exp = int.tryParse(await db.setting('hosted_token_exp') ?? '') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (cached != null && cached.isNotEmpty && exp - 300 > now) return cached;
    await refresh();
    final fresh = await db.setting('hosted_token');
    return (fresh == null || fresh.isEmpty) ? null : fresh;
  }

  @override
  Future<void> refresh() async {
    if (await tier() != Tier.premium) {
      await _store(null, 0);
      return;
    }
    final uid = await Purchases.appUserID;
    final client = _client ?? http.Client();
    try {
      final resp = await client
          .post(Uri.parse(tokenEndpoint),
              headers: {'content-type': 'application/json'},
              body: jsonEncode({'app_user_id': uid}))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        await _store(null, 0);
        return;
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store(body['token'] as String?, (body['expires_at'] as num?)?.toInt() ?? 0);
    } catch (_) {
      // Keep whatever we had; HostedProvider will surface a clear error.
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<void> _store(String? token, int exp) async {
    await db.putSetting('hosted_token', token ?? '');
    await db.putSetting('hosted_token_exp', '$exp');
  }

  // ------------------------------------------------------------ purchase

  /// The current offering's packages, for the paywall. Empty if offline or
  /// not configured.
  Future<List<Package>> packages() async {
    if (!_configured) return const [];
    try {
      final o = await Purchases.getOfferings();
      return o.current?.availablePackages ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Returns true if the user is premium after the purchase flow (including
  /// a cancelled sheet on an already-premium account).
  Future<bool> purchase(Package pkg) async {
    try {
      final info = await Purchases.purchasePackage(pkg);
      final premium = info.entitlements.active.containsKey(entitlementId);
      if (premium) await refresh();
      return premium;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return await tier() == Tier.premium;
      }
      rethrow;
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final premium = info.entitlements.active.containsKey(entitlementId);
      if (premium) await refresh();
      return premium;
    } catch (_) {
      return false;
    }
  }
}

