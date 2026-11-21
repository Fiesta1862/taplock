import 'package:flutter_test/flutter_test.dart';
import 'package:taplock/core/models.dart';
import 'package:taplock/core/modes_repository.dart';

void main() {
  test('saves, lists and deletes modes', () async {
    final repo = InMemoryModesRepository();
    final mode = FocusMode(
      id: 'study',
      name: 'Study',
      blockedBundleIds: const <String>['com.example.social'],
      createdAt: DateTime.utc(2026),
    );

    await repo.saveMode(mode);
    expect((await repo.listModes()).single.name, 'Study');
    expect((await repo.getMode('study'))!.blockedBundleIds, hasLength(1));

    await repo.deleteMode('study');
    expect(await repo.listModes(), isEmpty);
  });

  test('bindings require a known token id and an existing mode', () async {
    final repo = InMemoryModesRepository();
    final mode = FocusMode(
      id: 'work',
      name: 'Work',
      blockedBundleIds: const <String>[],
      createdAt: DateTime.utc(2026),
    );
    await repo.saveMode(mode);

    expect(
      () => repo.saveBinding(
        const TokenBinding(tokenId: 'x', modeId: 'work', label: 'bad'),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => repo.saveBinding(
        const TokenBinding(tokenId: 'token_01', modeId: 'nope', label: 'bad'),
      ),
      throwsA(isA<ArgumentError>()),
    );

    await repo.saveBinding(
      const TokenBinding(tokenId: 'token_01', modeId: 'work', label: 'Desk'),
    );
    expect((await repo.findBinding('token_01'))!.label, 'Desk');
  });

  test('export contains modes, bindings and sessions', () async {
    final repo = InMemoryModesRepository.seed();
    final snapshot = await repo.exportJson();

    expect(snapshot, contains('"schema": 1'));
    expect(snapshot, contains('Work'));
    expect(snapshot, contains('demo-token-01'));
  });

  test('focus mode JSON round trip preserves bundle ids', () {
    final mode = FocusMode(
      id: 'm1',
      name: 'Focus',
      blockedBundleIds: const <String>['a.b.c', 'd.e.f'],
      createdAt: DateTime.utc(2026, 1, 2),
    );

    final restored = FocusMode.fromJson(mode.toJson());
    expect(restored.blockedBundleIds, equals(mode.blockedBundleIds));
    expect(restored.createdAt, mode.createdAt);
  });
}
