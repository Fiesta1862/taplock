import 'package:flutter/material.dart';

import 'blocks/strategy_registry.dart';
import 'blocks/strategies/device_owner_block_strategy.dart';
import 'blocks/strategies/family_controls_block_strategy.dart';
import 'blocks/strategies/noop_block_strategy.dart';
import 'blocks/strategies/shizuku_block_strategy.dart';
import 'blocks/strategies/simulation_block_strategy.dart';
import 'core/modes_repository.dart';
import 'services/focus_controller.dart';
import 'ui/home_screen.dart';

class TaplockApp extends StatefulWidget {
  const TaplockApp({super.key});

  @override
  State<TaplockApp> createState() => _TaplockAppState();
}

class _TaplockAppState extends State<TaplockApp> {
  late final InMemoryModesRepository _repository;
  late final StrategyRegistry _strategies;
  late final FocusController _controller;

  @override
  void initState() {
    super.initState();
    _repository = InMemoryModesRepository.seed();
    _strategies = StrategyRegistry()
      ..register(const NoopBlockStrategy())
      ..register(const SimulationBlockStrategy())
      ..register(const ShizukuBlockStrategy())
      ..register(const DeviceOwnerBlockStrategy())
      ..register(const FamilyControlsBlockStrategy());
    _controller = FocusController(
      repository: _repository,
      strategies: _strategies,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taplock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF375AE4),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF375AE4),
        brightness: Brightness.dark,
      ),
      home: HomeScreen(
        repository: _repository,
        strategies: _strategies,
        controller: _controller,
      ),
    );
  }
}
