import '../block_strategy.dart';
import 'platform_channel_strategy.dart';

/// Android strong tier: DevicePolicyManager.setPackagesSuspended().
///
/// Only works when the app is device owner (ADB/QR provisioning). Intended for
/// family devices, kiosks and people who want the strongest guarantee.
class DeviceOwnerBlockStrategy extends PlatformChannelStrategy {
  const DeviceOwnerBlockStrategy() : super('app.taplock/blocks/deviceOwner');

  @override
  String get id => 'deviceOwner';

  @override
  String get displayName => 'Device owner (Android)';

  @override
  String get description =>
      'Suspends apps through DevicePolicyManager. Requires provisioning this '
      'app as device owner. Strong enforcement.';

  @override
  Set<StrategyCapability> get capabilities => const {StrategyCapability.enforce};
}
