import 'dart:async';

import 'models.dart';

/// Storage contract. Swap the in-memory implementation for a persistent one
/// (Drift/Isar/SharedPreferences) without touching the controller or UI.
abstract class ModesRepository {
  Future<List<FocusMode>> listModes();
  Future<FocusMode?> getMode(String id);
  Future<void> saveMode(FocusMode mode);
  Future<void> deleteMode(String id);

  Future<List<TokenBinding>> listBindings();
  Future<TokenBinding?> findBinding(String tokenId);
  Future<void> saveBinding(TokenBinding binding);
  Future<void> deleteBinding(String tokenId);

  Future<List<FocusSession>> listSessions();
  Future<void> saveSession(FocusSession session);

  Future<String> exportJson();
}

/// Reference implementation used by tests and the demo app.
class InMemoryModesRepository implements ModesRepository {
  final Map<String, FocusMode> _modes = <String, FocusMode>{};
  final Map<String, TokenBinding> _bindings = <String, TokenBinding>{};
  final List<FocusSession> _sessions = <FocusSession>[];

  InMemoryModesRepository();

  factory InMemoryModesRepository.seed() {
    final repo = InMemoryModesRepository();
    final now = DateTime.now();
    final work = FocusMode(
      id: 'work',
      name: 'Work',
      description: 'Keep the essentials, block the rest.',
      blockedBundleIds: const <String>[
        'com.instagram.android',
        'com.tencent.mm',
        'com.youtube.android',
      ],
      createdAt: now,
    );
    repo._modes[work.id] = work;
    repo._bindings['demo-token-01'] = const TokenBinding(
      tokenId: 'demo-token-01',
      modeId: 'work',
      label: 'Desk tag',
    );
    return repo;
  }

  @override
  Future<List<FocusMode>> listModes() async =>
      List<FocusMode>.unmodifiable(_modes.values);

  @override
  Future<FocusMode?> getMode(String id) async => _modes[id];

  @override
  Future<void> saveMode(FocusMode mode) async {
    if (mode.name.trim().isEmpty) {
      throw ArgumentError('Mode name must not be empty.');
    }
    _modes[mode.id] = mode;
  }

  @override
  Future<void> deleteMode(String id) async {
    _modes.remove(id);
    _bindings.removeWhere((_, binding) => binding.modeId == id);
  }

  @override
  Future<List<TokenBinding>> listBindings() async =>
      List<TokenBinding>.unmodifiable(_bindings.values);

  @override
  Future<TokenBinding?> findBinding(String tokenId) async =>
      _bindings[tokenId];

  @override
  Future<void> saveBinding(TokenBinding binding) async {
    if (!_tokenIdPattern.hasMatch(binding.tokenId)) {
      throw ArgumentError('Malformed token ID: ${binding.tokenId}');
    }
    if (!_modes.containsKey(binding.modeId)) {
      throw ArgumentError('Unknown mode: ${binding.modeId}');
    }
    _bindings[binding.tokenId] = binding;
  }

  @override
  Future<void> deleteBinding(String tokenId) async {
    _bindings.remove(tokenId);
  }

  @override
  Future<List<FocusSession>> listSessions() async =>
      List<FocusSession>.unmodifiable(_sessions);

  @override
  Future<void> saveSession(FocusSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index == -1) {
      _sessions.add(session);
    } else {
      _sessions[index] = session;
    }
  }

  @override
  Future<String> exportJson() async => encodeSnapshot(
        modes: await listModes(),
        bindings: await listBindings(),
        sessions: await listSessions(),
      );
}

final RegExp _tokenIdPattern = RegExp(r'^[A-Za-z0-9_-]{6,64}$');
