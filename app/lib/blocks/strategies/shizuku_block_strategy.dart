import '../block_strategy.dart';
import 'platform_channel_strategy.dart';

/// Android practical tier: Shizuku grants shell-level `pm suspend` without
/// root. User grants access once via wireless debugging.
///
/// Native implementation: platform_overlays/android/.../ShizukuBlockStrategy.kt
class ShizukuBlockStrategy extends PlatformChannelStrategy {
  const ShizukuBlockStrategy() : super('app.taplock/blocks/shizuku');

  @override
  String get id => 'shizuku';

  @override
  String get displayName => 'Shizuku (recommended on Android)';

  @override
  String get description =>
      'Suspends packages via shell permission. Needs a one-time Shizuku grant, '
      'no root. Strong enforcement.';

  @override
  Set<StrategyCapability> get capabilities => const {StrategyCapability.enforce};
}
