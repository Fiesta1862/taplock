import 'package:flutter_test/flutter_test.dart';
import 'package:taplock/blocks/block_strategy.dart';
import 'package:taplock/blocks/strategy_registry.dart';
import 'package:taplock/blocks/strategies/simulation_block_strategy.dart';
import 'package:taplock/core/models.dart';
import 'package:taplock/core/modes_repository.dart';
import 'package:taplock/core/nfc_payload.dart';
import 'package:taplock/services/focus_controller.dart';

class _FakeStrategy implements BlockStrategy {
  bool active = false;

  @override
  String get id => 'fake';

  @override
  String get displayName => 'Fake enforcer';

  @override
  String get description => 'Test only';

  @override
  Set<StrategyCapability> get capabilities => const {StrategyCapability.enforce};

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BlockState> currentState() async =>
      active ? BlockState.active : BlockState.inactive;

  @override
  Future<BlockResult> applyBlock(BlockRequest request) async {
    active = true;
    return const BlockResult(true, 'Blocked');
  }

  @override
  Future<BlockResult> releaseBlock({required String tokenId}) async {
    active = false;
    return const BlockResult(true, 'Released');
  }
}

void main() {
  late InMemoryModesRepository repo;
  late StrategyRegistry registry;
  late _FakeStrategy strategy;
  late FocusController controller;

  setUp(() async {
    repo = InMemoryModesRepository();
    await repo.saveMode(
      FocusMode(
        id: 'work',
        name: 'Work',
        blockedBundleIds: const <String>['com.example.social'],
        createdAt: DateTime.utc(2026),
      ),
    );
    await repo.saveBinding(
      const TokenBinding(tokenId: 'token_01', modeId: 'work', label: 'Desk'),
    );
    strategy = _FakeStrategy();
    registry = StrategyRegistry()..register(strategy);
    controller = FocusController(
      repository: repo,
      strategies: registry,
      preferredStrategyId: 'fake',
    );
  });

  test('toggle starts a session and a second tap ends it', () async {
    final url = buildTagUrl(tokenId: 'token_01', action: NfcAction.toggle);

    final first = await controller.handleTagUrl(url);
    expect(first.ok, isTrue);
    expect(controller.activeSession, isNotNull);
    expect(controller.activeSession!.modeId, 'work');
    expect(strategy.active, isTrue);

    final second = await controller.handleTagUrl(url);
    expect(second.ok, isTrue);
    expect(second.session!.isActive, isFalse);
    expect(controller.activeSession, isNull);
    expect(strategy.active, isFalse);
  });

  test('rejects unknown tokens', () async {
    final url = buildTagUrl(tokenId: 'unknown_1', action: NfcAction.lock);
    final outcome = await controller.handleTagUrl(url);

    expect(outcome.ok, isFalse);
    expect(outcome.message, contains('Unknown token'));
  });

  test('rejects malformed payloads', () async {
    final outcome = await controller.handleTagUrl('not a url');
    expect(outcome.ok, isFalse);
  });

  test('falls back to the simulation strategy with an explicit warning',
      () async {
    final simRegistry = StrategyRegistry()
      ..register(const SimulationBlockStrategy());
    final simController = FocusController(
      repository: repo,
      strategies: simRegistry,
    );

    final outcome = await simController.handleTagUrl(
      buildTagUrl(tokenId: 'token_01', action: NfcAction.lock),
    );

    expect(outcome.ok, isTrue);
    expect(outcome.message, contains('Simulation only'));
    expect(simController.activeSession!.strategyId, 'simulation');
  });
}
