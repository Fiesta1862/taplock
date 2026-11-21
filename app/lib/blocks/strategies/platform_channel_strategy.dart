import 'package:flutter/services.dart';

import '../block_strategy.dart';

/// Shared MethodChannel plumbing for native strategies.
///
/// The native side receives:
///   apply    -> { 'tokenId': String, 'bundleIds': List<String>,
///                 'durationMinutes': int? }
///   release  -> { 'tokenId': String }
/// and replies with a map: { 'applied': bool, 'message': String }.
abstract class PlatformChannelStrategy implements BlockStrategy {
  const PlatformChannelStrategy(this.channelName);

  final String channelName;

  MethodChannel get _channel => MethodChannel(channelName);

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<BlockState> currentState() async {
    try {
      final value = await _channel.invokeMethod<String>('currentState');
      switch (value) {
        case 'active':
          return BlockState.active;
        case 'unavailable':
          return BlockState.unavailable;
        default:
          return BlockState.inactive;
      }
    } on PlatformException {
      return BlockState.unavailable;
    } on MissingPluginException {
      return BlockState.unavailable;
    }
  }

  @override
  Future<BlockResult> applyBlock(BlockRequest request) async {
    try {
      final reply = await _channel.invokeMapMethod<String, dynamic>(
        'apply',
        <String, dynamic>{
          'tokenId': request.tokenId,
          'bundleIds': request.mode.blockedBundleIds,
          'modeId': request.mode.id,
          'durationMinutes': request.durationMinutes,
        },
      );
      return _resultFrom(reply);
    } on PlatformException catch (e) {
      return BlockResult(false, e.message ?? 'Unknown platform error.');
    } on MissingPluginException {
      return const BlockResult(false, 'Native implementation is missing.');
    }
  }

  @override
  Future<BlockResult> releaseBlock({required String tokenId}) async {
    try {
      final reply = await _channel.invokeMapMethod<String, dynamic>(
        'release',
        <String, dynamic>{'tokenId': tokenId},
      );
      return _resultFrom(reply);
    } on PlatformException catch (e) {
      return BlockResult(false, e.message ?? 'Unknown platform error.');
    } on MissingPluginException {
      return const BlockResult(false, 'Native implementation is missing.');
    }
  }

  BlockResult _resultFrom(Map<String, dynamic>? reply) {
    if (reply == null) {
      return const BlockResult(false, 'Native side returned no result.');
    }
    return BlockResult(
      reply['applied'] == true,
      reply['message'] as String? ?? 'No details returned.',
    );
  }
}
