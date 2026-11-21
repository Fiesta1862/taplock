import '../blocks/block_strategy.dart';
import '../blocks/strategy_registry.dart';
import '../core/models.dart';
import '../core/modes_repository.dart';
import '../core/nfc_payload.dart';

class CommandOutcome {
  final bool ok;
  final String message;
  final FocusSession? session;

  const CommandOutcome(this.ok, this.message, this.session);
}

/// Turns a scanned tag URL into a state change.
///
/// Deliberately free of Flutter/UI imports so it is unit-testable on the VM.
class FocusController {
  FocusController({
    required this.repository,
    required this.strategies,
    this.preferredStrategyId = 'shizuku',
    this.expectedHost,
  });

  final ModesRepository repository;
  final StrategyRegistry strategies;
  final String? expectedHost;

  /// Strategy tried first. Falls back to any available enforcing strategy.
  String preferredStrategyId;

  FocusSession? activeSession;

  Future<CommandOutcome> handleTagUrl(String url) async {
    final NfcCommand command;
    try {
      command = parseTagUrl(url, expectedHost: expectedHost);
    } on NfcPayloadException catch (e) {
      return CommandOutcome(false, e.message, null);
    }

    final binding = await repository.findBinding(command.tokenId);
    if (binding == null) {
      return CommandOutcome(
        false,
        'Unknown token ${command.tokenId}. Bind it in the app first.',
        null,
      );
    }

    var action = command.action;
    if (action == NfcAction.toggle) {
      action = activeSession == null ? NfcAction.lock : NfcAction.unlock;
    }

    return action == NfcAction.lock
        ? _lock(binding, command)
        : _unlock(command);
  }

  Future<CommandOutcome> _lock(
    TokenBinding binding,
    NfcCommand command,
  ) async {
    if (activeSession != null) {
      return const CommandOutcome(false, 'Already in a focus session.', null);
    }

    final mode = await repository.getMode(binding.modeId);
    if (mode == null) {
      return CommandOutcome(false, 'Mode ${binding.modeId} no longer exists.', null);
    }

    final strategy = await _pickStrategy();
    if (strategy == null) {
      return const CommandOutcome(
        false,
        'No blocking strategy is available on this device.',
        null,
      );
    }

    final result = await strategy.applyBlock(
      BlockRequest(
        mode: mode,
        tokenId: command.tokenId,
        durationMinutes: command.durationMinutes,
      ),
    );
    if (!result.applied) {
      return CommandOutcome(false, result.message, null);
    }

    final session = FocusSession(
      id: '${command.tokenId}-${DateTime.now().microsecondsSinceEpoch}',
      tokenId: command.tokenId,
      modeId: mode.id,
      strategyId: strategy.id,
      startedAt: DateTime.now(),
    );
    activeSession = session;
    await repository.saveSession(session);

    return CommandOutcome(
      true,
      '${mode.name} is active via ${strategy.displayName}. ${result.message}',
      session,
    );
  }

  Future<CommandOutcome> _unlock(NfcCommand command) async {
    final session = activeSession;
    if (session == null) {
      return const CommandOutcome(false, 'Nothing is blocked right now.', null);
    }

    final strategy = strategies.get(session.strategyId);
    if (strategy == null) {
      return const CommandOutcome(false, 'Original strategy is unavailable.', null);
    }

    final result = await strategy.releaseBlock(tokenId: command.tokenId);
    if (!result.applied) {
      return CommandOutcome(false, result.message, null);
    }

    final ended = session.end(DateTime.now(), reason: 'tag');
    activeSession = null;
    await repository.saveSession(ended);

    return CommandOutcome(true, 'Unblocked. Focus session saved.', ended);
  }

  Future<BlockStrategy?> _pickStrategy() async {
    bool canRun(BlockStrategy strategy) =>
        strategy.capabilities.contains(StrategyCapability.enforce) ||
        strategy.capabilities.contains(StrategyCapability.simulate);

    final preferred = strategies.get(preferredStrategyId);
    if (preferred != null && canRun(preferred) && await preferred.isAvailable()) {
      return preferred;
    }
    for (final candidate in strategies.all) {
      if (canRun(candidate) && await candidate.isAvailable()) return candidate;
    }
    return null;
  }
}
