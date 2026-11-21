import 'dart:convert';

/// A named group of apps plus the rules for blocking them.
class FocusMode {
  final String id;
  final String name;
  final String? description;
  final List<String> blockedBundleIds;
  final int? dailyLimitMinutes;
  final DateTime createdAt;

  const FocusMode({
    required this.id,
    required this.name,
    required this.blockedBundleIds,
    required this.createdAt,
    this.description,
    this.dailyLimitMinutes,
  });

  factory FocusMode.fromJson(Map<String, dynamic> json) {
    return FocusMode(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      blockedBundleIds: _stringList(json['blockedBundleIds']),
      dailyLimitMinutes: json['dailyLimitMinutes'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'blockedBundleIds': blockedBundleIds,
        if (dailyLimitMinutes != null) 'dailyLimitMinutes': dailyLimitMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  FocusMode copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? blockedBundleIds,
    int? dailyLimitMinutes,
    DateTime? createdAt,
  }) {
    return FocusMode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      blockedBundleIds: blockedBundleIds ?? this.blockedBundleIds,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Maps a physical token to a mode (e.g. the red tag = Work mode).
class TokenBinding {
  final String tokenId;
  final String modeId;
  final String label;

  const TokenBinding({
    required this.tokenId,
    required this.modeId,
    required this.label,
  });

  factory TokenBinding.fromJson(Map<String, dynamic> json) {
    return TokenBinding(
      tokenId: json['tokenId'] as String,
      modeId: json['modeId'] as String,
      label: json['label'] as String? ?? 'Unnamed token',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tokenId': tokenId,
        'modeId': modeId,
        'label': label,
      };
}

/// One lock session, from tap to un-tap.
class FocusSession {
  final String id;
  final String tokenId;
  final String modeId;
  final String strategyId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? endReason;

  const FocusSession({
    required this.id,
    required this.tokenId,
    required this.modeId,
    required this.strategyId,
    required this.startedAt,
    this.endedAt,
    this.endReason,
  });

  bool get isActive => endedAt == null;

  Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);

  FocusSession end(DateTime endTime, {required String reason}) {
    return FocusSession(
      id: id,
      tokenId: tokenId,
      modeId: modeId,
      strategyId: strategyId,
      startedAt: startedAt,
      endedAt: endTime,
      endReason: reason,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'tokenId': tokenId,
        'modeId': modeId,
        'strategyId': strategyId,
        'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
        if (endReason != null) 'endReason': endReason,
      };
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return List<String>.unmodifiable(value.whereType<String>());
}

/// Stable, readable snapshot for backup/export.
String encodeSnapshot({
  required List<FocusMode> modes,
  required List<TokenBinding> bindings,
  required List<FocusSession> sessions,
}) {
  final payload = <String, dynamic>{
    'schema': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'modes': modes.map((m) => m.toJson()).toList(),
    'bindings': bindings.map((b) => b.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
  return const JsonEncoder.withIndent('  ').convert(payload);
}
