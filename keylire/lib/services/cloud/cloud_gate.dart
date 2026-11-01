import '../settings/settings_service.dart';
import 'cloud_provider.dart';

/// Decides, per feature, whether a cloud call is allowed and through whom.
/// Hosted (Premium) beats BYOK when both are configured. A feature the user
/// has not turned on returns null — callers treat null as "stay local".
class CloudGate {
  CloudGate({required this.settings, this.hosted, this.byok});
  final SettingsService settings;
  final CloudProvider? hosted;
  final CloudProvider? byok;

  /// Nothing is ever sent for this feature.
  static CloudGate disabled(SettingsService s) => CloudGate(settings: s);

  Future<CloudProvider?> providerFor(CloudFeature f) async {
    if (!await settings.cloudFeatureEnabled(f)) return null;
    if (hosted != null && await hosted!.isConfigured) return hosted;
    if (byok != null && await byok!.isConfigured) return byok;
    return null;
  }

  /// For the Settings screen: could this feature work if toggled on?
  Future<bool> get anyProviderAvailable async =>
      (hosted != null && await hosted!.isConfigured) ||
      (byok != null && await byok!.isConfigured);
}

