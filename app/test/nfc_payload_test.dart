import 'package:flutter_test/flutter_test.dart';
import 'package:taplock/core/nfc_payload.dart';

void main() {
  group('NFC payload codec', () {
    test('round-trips a lock command with all fields', () {
      final url = buildTagUrl(
        tokenId: 'desk_tag_01',
        action: NfcAction.lock,
        modeId: 'work',
        durationMinutes: 90,
        host: 'taplock.example',
      );

      final command = parseTagUrl(url, expectedHost: 'taplock.example');

      expect(command.tokenId, 'desk_tag_01');
      expect(command.action, NfcAction.lock);
      expect(command.modeId, 'work');
      expect(command.durationMinutes, 90);
      expect(command.version, '1');
    });

    test('defaults to toggle without optional fields', () {
      final url = buildTagUrl(tokenId: 'abc123', action: NfcAction.toggle);
      final command = parseTagUrl(url);

      expect(command.action, NfcAction.toggle);
      expect(command.modeId, isNull);
      expect(command.durationMinutes, isNull);
    });

    test('rejects http, wrong host, wrong path and bad versions', () {
      expect(
        () => parseTagUrl('http://taplock.example/t?v=1&i=abc123&a=lock'),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => parseTagUrl(
          'https://evil.example/t?v=1&i=abc123&a=lock',
          expectedHost: 'taplock.example',
        ),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => parseTagUrl('https://taplock.example/other?v=1&i=abc123&a=lock'),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => parseTagUrl('https://taplock.example/t?v=9&i=abc123&a=lock'),
        throwsA(isA<NfcPayloadException>()),
      );
    });

    test('rejects malformed token ids, actions and durations', () {
      expect(
        () => parseTagUrl('https://taplock.example/t?v=1&i=ab&a=lock'),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => parseTagUrl('https://taplock.example/t?v=1&i=abc123&a=nuke'),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => parseTagUrl(
          'https://taplock.example/t?v=1&i=abc123&a=lock&d=9999',
        ),
        throwsA(isA<NfcPayloadException>()),
      );
    });

    test('encoder validates its own inputs', () {
      expect(
        () => buildTagUrl(tokenId: 'bad id', action: NfcAction.lock),
        throwsA(isA<NfcPayloadException>()),
      );
      expect(
        () => buildTagUrl(
          tokenId: 'abc123',
          action: NfcAction.lock,
          durationMinutes: 0,
        ),
        throwsA(isA<NfcPayloadException>()),
      );
    });
  });
}
