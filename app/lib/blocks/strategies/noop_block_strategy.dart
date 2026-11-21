import '../block_strategy.dart';

/// Reference implementation and test double.
///
/// Does nothing except report what would happen. Useful for learning the
/// interface and for running the app on a desktop where no OS API exists.
class NoopBlockStrategy implements BlockStrategy {
  const NoopBlockStrategy();

  @override
  String get id => 'noop';

  @override
  String get displayName => 'Dry run (no enforcement)';

  @override
  String get description =>
      'Shows what a real strategy would do. Anyone can dismiss it.';

  @override
  Set<StrategyCapability> get capabilities => const {StrategyCapability.notify};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BlockState> currentState() async => BlockState.inactive;

  @override
  Future<BlockResult> applyBlock(BlockRequest request) async {
    return const BlockResult(
      false,
      'Dry run: no apps were actually blocked.',
    );
  }

  @override
  Future<BlockResult> releaseBlock({required String tokenId}) async {
    return const BlockResult(true, 'Dry run: nothing to release.');
  }
}
