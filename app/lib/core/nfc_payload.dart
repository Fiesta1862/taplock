import 'action.dart';

export 'action.dart' show NfcAction, NfcActionX, NfcPayloadException;

/// Placeholder host. Replace it with a domain you control before shipping:
/// iOS background NFC reading requires an NDEF URI record matching an
/// associated domain (applinks:). See docs/NFC_PROTOCOL.md.
const String defaultTagHost = 'taplock.example';

const String _tagPath = '/t';
const String _protocolVersion = '1';

final RegExp _tokenIdPattern = RegExp(r'^[A-Za-z0-9_-]{6,64}$');

/// A decoded command read from a physical token.
class NfcCommand {
  final String version;
  final String tokenId;
  final NfcAction action;
  final String? modeId;
  final int? durationMinutes;

  const NfcCommand({
    required this.version,
    required this.tokenId,
    required this.action,
    this.modeId,
    this.durationMinutes,
  });

  @override
  String toString() =>
      'NfcCommand(tokenId: $tokenId, action: ${action.wireValue}, '
      'modeId: $modeId, durationMinutes: $durationMinutes)';
}

/// Encodes a command as the HTTPS URL written to an NDEF URI record.
///
/// A URI record (rather than a custom MIME record) is required for iOS to
/// read tags while the app is in the background.
String buildTagUrl({
  required String tokenId,
  required NfcAction action,
  String? modeId,
  int? durationMinutes,
  String host = defaultTagHost,
}) {
  if (!_tokenIdPattern.hasMatch(tokenId)) {
    throw const NfcPayloadException(
      'Token ID must be 6-64 characters of A-Z, a-z, 0-9, _ or -.',
    );
  }
  if (modeId != null && modeId.isEmpty) {
    throw const NfcPayloadException('modeId must not be empty.');
  }
  if (durationMinutes != null &&
      (durationMinutes < 1 || durationMinutes > 1440)) {
    throw const NfcPayloadException(
      'durationMinutes must be between 1 and 1440.',
    );
  }
  if (host.isEmpty) {
    throw const NfcPayloadException('host must not be empty.');
  }

  final params = <String, String>{
    'v': _protocolVersion,
    'i': tokenId,
    'a': action.wireValue,
  };
  if (modeId != null) params['m'] = modeId;
  if (durationMinutes != null) params['d'] = '$durationMinutes';

  return Uri.https(host, _tagPath, params).toString();
}

/// Decodes and validates a URL read from a tag.
///
/// Pass [expectedHost] in production so a tag pointing at another domain is
/// rejected instead of being trusted.
NfcCommand parseTagUrl(String input, {String? expectedHost}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const NfcPayloadException('Tag payload is empty.');
  }

  final Uri uri;
  try {
    uri = Uri.parse(trimmed);
  } on FormatException {
    throw const NfcPayloadException('Tag payload is not a valid URL.');
  }

  if (uri.scheme != 'https') {
    throw const NfcPayloadException('Tag URL must use https.');
  }

  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    throw const NfcPayloadException('Tag URL has no host.');
  }
  if (expectedHost != null && host != expectedHost.toLowerCase()) {
    throw NfcPayloadException(
      'Tag host "$host" does not match expected host "$expectedHost".',
    );
  }

  final path = uri.path.replaceAll(RegExp(r'/+$'), '');
  if (path != _tagPath) {
    throw NfcPayloadException('Tag URL path must be $_tagPath, got "$path".');
  }

  final params = uri.queryParameters;
  if (params['v'] != _protocolVersion) {
    throw NfcPayloadException(
      'Unsupported protocol version: ${params['v']}.',
    );
  }

  final tokenId = params['i'];
  if (tokenId == null || !_tokenIdPattern.hasMatch(tokenId)) {
    throw const NfcPayloadException('Missing or malformed token ID.');
  }

  final action = nfcActionFromWire(params['a']);

  final modeId = params['m'];
  if (modeId != null && modeId.isEmpty) {
    throw const NfcPayloadException('modeId must not be empty.');
  }

  int? durationMinutes;
  final rawDuration = params['d'];
  if (rawDuration != null) {
    durationMinutes = int.tryParse(rawDuration);
    if (durationMinutes == null ||
        durationMinutes < 1 ||
        durationMinutes > 1440) {
      throw NfcPayloadException(
        'Invalid durationMinutes: $rawDuration.',
      );
    }
  }

  return NfcCommand(
    version: params['v']!,
    tokenId: tokenId,
    action: action,
    modeId: modeId,
    durationMinutes: durationMinutes,
  );
}
