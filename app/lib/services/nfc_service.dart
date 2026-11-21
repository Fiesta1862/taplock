import 'package:flutter/services.dart';

/// Bridge to CoreNFC (iOS) and NDEF_DISCOVERED intents (Android).
///
/// Native implementations emit the raw URL string; all parsing/validation
/// happens in the pure-Dart codec so both platforms behave identically.
class NfcService {
  static const MethodChannel _commands = MethodChannel('app.taplock/nfc');
  static const EventChannel _tags = EventChannel('app.taplock/nfc/tags');

  Stream<String> get tagUrls =>
      _tags.receiveBroadcastStream().map((event) => event.toString());

  Future<bool> isAvailable() async {
    try {
      return await _commands.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// iOS cannot begin a read session from a broadcast receiver unless the tag
  /// is a matching universal-link URI. This gives users an explicit scan button.
  Future<void> scanOnce() async {
    try {
      await _commands.invokeMethod<void>('scanOnce');
    } on PlatformException {
      // Surface an error in the UI in a later iteration.
    } on MissingPluginException {
      // Running on a platform without NFC (e.g. desktop).
    }
  }
}
