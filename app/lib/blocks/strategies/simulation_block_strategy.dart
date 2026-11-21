import '../block_strategy.dart';

/// Lets the full tap → session → tap flow be demonstrated without pretending
/// that any app was actually blocked.
///
/// Sessions started here are labelled with strategy id `simulation` and the
/// result message says explicitly that nothing was enforced.
class SimulationBlockStrategy implements BlockStrategy {
  const SimulationBlockStrategy();

  @override
  String get id => 'simulation';

  @override
  String get displayName => 'Simulation (demo only)';

  @override
  String get description =>
      'Runs the complete tap/session flow but does not block any apps. '
      'Use this to try the app before real enforcement is available.';

  @override
  Set<StrategyCapability> get capabilities => const {
        StrategyCapability.simulate,
        StrategyCapability.notify,
      };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BlockState> currentState() async => BlockState.inactive;

  @override
  Future<BlockResult> applyBlock(BlockRequest request) async {
    return const BlockResult(
      true,
      'Simulation only: session started, but no apps were blocked.',
    );
  }

  @override
  Future<BlockResult> releaseBlock({required String tokenId}) async {
    return const BlockResult(true, 'Simulation session ended.');
  }
}
