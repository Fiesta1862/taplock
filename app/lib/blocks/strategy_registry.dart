import 'block_strategy.dart';

/// Registry of available blocking implementations.
///
/// Adding a new strategy should be a one-line registration in the app shell,
/// which is what makes this a friendly first contribution.
class StrategyRegistry {
  final Map<String, BlockStrategy> _strategies = <String, BlockStrategy>{};

  void register(BlockStrategy strategy) {
    if (_strategies.containsKey(strategy.id)) {
      throw ArgumentError('Duplicate strategy id: ${strategy.id}');
    }
    _strategies[strategy.id] = strategy;
  }

  BlockStrategy? get(String id) => _strategies[id];

  List<BlockStrategy> get all => List<BlockStrategy>.unmodifiable(
        _strategies.values.toList(),
      );

  List<BlockStrategy> get enforcing => all
      .where((s) => s.capabilities.contains(StrategyCapability.enforce))
      .toList(growable: false);
}
