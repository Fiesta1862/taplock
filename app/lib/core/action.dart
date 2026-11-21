/// Actions that can be carried by an NFC token.
///
/// Keep the wire values stable: tags written today must remain readable by
/// future versions of the app. See docs/NFC_PROTOCOL.md.
enum NfcAction { lock, unlock, toggle }

extension NfcActionX on NfcAction {
  String get wireValue {
    switch (this) {
      case NfcAction.lock:
        return 'lock';
      case NfcAction.unlock:
        return 'unlock';
      case NfcAction.toggle:
        return 'toggle';
    }
  }
}

NfcAction nfcActionFromWire(String? value) {
  switch (value) {
    case 'lock':
      return NfcAction.lock;
    case 'unlock':
      return NfcAction.unlock;
    case 'toggle':
      return NfcAction.toggle;
    default:
      throw NfcPayloadException('Unsupported action: $value');
  }
}

/// Thrown when a scanned tag does not match the Taplock protocol.
///
/// Declared here so [nfcActionFromWire] can use it without importing the codec.
class NfcPayloadException implements Exception {
  final String message;

  const NfcPayloadException(this.message);

  @override
  String toString() => 'NfcPayloadException: $message';
}
