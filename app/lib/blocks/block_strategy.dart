import '../core/models.dart';

/// How much enforcement a strategy actually provides.
///
/// This is surfaced in the UI so nobody mistakes a reminder for a hard block.
enum StrategyCapability { enforce, notify, simulate }

enum BlockState { active, inactive, unavailable }

class BlockRequest {
  final FocusMode mode;
  final String tokenId;
  final int? durationMinutes;

  const BlockRequest({
    required this.mode,
    required this.tokenId,
    this.durationMinutes,
  });
}

class BlockResult {
  final bool applied;
  final String message;

  const BlockResult(this.applied, this.message);
}

/// Platform-specific enforcement lives behind this interface.
///
/// Implementations must be honest about [capabilities]: a strategy that only
/// shows a warning must report [StrategyCapability.notify], not [enforce].
abstract class BlockStrategy {
  String get id;
  String get displayName;
  String get description;
  Set<StrategyCapability> get capabilities;

  Future<bool> isAvailable();
  Future<BlockState> currentState();
  Future<BlockResult> applyBlock(BlockRequest request);
  Future<BlockResult> releaseBlock({required String tokenId});
}
