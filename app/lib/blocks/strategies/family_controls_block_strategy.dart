import '../block_strategy.dart';
import 'platform_channel_strategy.dart';

/// iOS strong tier: Family Controls + ManagedSettings + DeviceActivity.
///
/// Requires the `com.apple.developer.family-controls` entitlement from Apple.
/// The app must degrade gracefully until it is approved.
class FamilyControlsBlockStrategy extends PlatformChannelStrategy {
  const FamilyControlsBlockStrategy()
      : super('app.taplock/blocks/familyControls');

  @override
  String get id => 'familyControls';

  @override
  String get displayName => 'Screen Time (iOS)';

  @override
  String get description =>
      'Shields selected apps using Apple Family Controls. Requires Apple '
      'entitlement approval. Strong enforcement.';

  @override
  Set<StrategyCapability> get capabilities => const {StrategyCapability.enforce};
}
