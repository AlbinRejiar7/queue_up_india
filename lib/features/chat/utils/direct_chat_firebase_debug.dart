import 'dart:async';

import 'package:flutter/foundation.dart';

abstract final class DirectChatFirebaseDebug {
  static int _lifetimeReads = 0;
  static int _lifetimeWrites = 0;
  static int _sessionReads = 0;
  static int _sessionWrites = 0;
  static String _sessionLabel = 'default';
  static int _nextActionId = 0;
  static final Map<String, int> _sessionReadBuckets = <String, int>{};
  static final Map<String, int> _sessionWriteBuckets = <String, int>{};
  static final Map<int, _DebugSnapshot> _actionSnapshots =
      <int, _DebugSnapshot>{};

  static void resetSession(String label) {
    if (!kDebugMode) {
      return;
    }
    _sessionLabel = label;
    _sessionReads = 0;
    _sessionWrites = 0;
    _sessionReadBuckets.clear();
    _sessionWriteBuckets.clear();
    _actionSnapshots.clear();
    debugPrint('[DirectChatFirebase] SESSION START label=$label');
  }

  static int startAction(String label) {
    if (!kDebugMode) {
      return -1;
    }
    final actionId = ++_nextActionId;
    _actionSnapshots[actionId] = _captureSnapshot(label);
    debugPrint(
      '[DirectChatFirebase] ACTION START id=$actionId session=$_sessionLabel '
      'label=$label reads=$_sessionReads writes=$_sessionWrites',
    );
    return actionId;
  }

  static void summarizeAction(int actionId, {required String reason}) {
    if (!kDebugMode) {
      return;
    }
    final start = _actionSnapshots.remove(actionId);
    if (start == null) {
      return;
    }
    final readDelta = _sessionReads - start.reads;
    final writeDelta = _sessionWrites - start.writes;
    final readBuckets = _bucketDelta(_sessionReadBuckets, start.readBuckets);
    final writeBuckets = _bucketDelta(_sessionWriteBuckets, start.writeBuckets);
    debugPrint(
      '[DirectChatFirebase] ACTION SUMMARY id=$actionId session=$_sessionLabel '
      'label=${start.label} reason=$reason reads=$readDelta writes=$writeDelta '
      'readBuckets=${_formatBuckets(readBuckets)} '
      'writeBuckets=${_formatBuckets(writeBuckets)}',
    );
  }

  static void summarizeActionAfterDelay(
    int actionId, {
    required String reason,
    Duration delay = const Duration(milliseconds: 900),
  }) {
    if (!kDebugMode || actionId < 0) {
      return;
    }
    unawaited(
      Future<void>.delayed(delay, () {
        summarizeAction(actionId, reason: reason);
      }),
    );
  }

  static void summarizeSession(String reason) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(
      '[DirectChatFirebase] SESSION SUMMARY label=$_sessionLabel '
      'reason=$reason reads=$_sessionReads writes=$_sessionWrites '
      'readBuckets=${_formatBuckets(_sessionReadBuckets)} '
      'writeBuckets=${_formatBuckets(_sessionWriteBuckets)}',
    );
  }

  static void read({
    required String source,
    required int count,
    String? detail,
  }) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    final bucket = _bucketForSource(source, isWrite: false);
    _lifetimeReads += count;
    _sessionReads += count;
    _sessionReadBuckets.update(
      bucket,
      (value) => value + count,
      ifAbsent: () => count,
    );
    debugPrint(
      '[DirectChatFirebase] READ +$count session=$_sessionReads total=$_lifetimeReads '
      'bucket=$bucket source=$source${_suffix(detail)}',
    );
  }

  static void write({
    required String source,
    required int count,
    String? detail,
  }) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    final bucket = _bucketForSource(source, isWrite: true);
    _lifetimeWrites += count;
    _sessionWrites += count;
    _sessionWriteBuckets.update(
      bucket,
      (value) => value + count,
      ifAbsent: () => count,
    );
    debugPrint(
      '[DirectChatFirebase] WRITE +$count session=$_sessionWrites total=$_lifetimeWrites '
      'bucket=$bucket source=$source${_suffix(detail)}',
    );
  }

  static void info(String source, String detail) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[DirectChatFirebase] INFO source=$source detail=$detail');
  }

  static String _suffix(String? detail) {
    if (detail == null || detail.trim().isEmpty) {
      return '';
    }
    return ' detail=$detail';
  }

  static String _bucketForSource(String source, {required bool isWrite}) {
    if (source.startsWith('watchLatestDirectMessages') ||
        source.startsWith('fetchOlderDirectMessages') ||
        source.startsWith('getDirectChatUnreadCount')) {
      return 'message-stream';
    }
    if (source.startsWith('watchDirectThreadsPage') ||
        source.startsWith('fetchDirectThreadsPage') ||
        source.startsWith('watchHasUnreadDirectThreads') ||
        source.startsWith('DirectChatMonitorService')) {
      return 'chat-list';
    }
    if (source.contains('blockList') ||
        source.startsWith('_resolvePeerProfiles') ||
        source.startsWith('hasDirectChat')) {
      return 'support';
    }
    if (isWrite ||
        source.startsWith('sendDirectMessage') ||
        source.startsWith('markDirectChatRead')) {
      return 'chat-write';
    }
    return 'other';
  }

  static _DebugSnapshot _captureSnapshot(String label) {
    return _DebugSnapshot(
      label: label,
      reads: _sessionReads,
      writes: _sessionWrites,
      readBuckets: Map<String, int>.from(_sessionReadBuckets),
      writeBuckets: Map<String, int>.from(_sessionWriteBuckets),
    );
  }

  static Map<String, int> _bucketDelta(
    Map<String, int> current,
    Map<String, int> previous,
  ) {
    final keys = <String>{...current.keys, ...previous.keys};
    return <String, int>{
      for (final key in keys)
        if ((current[key] ?? 0) - (previous[key] ?? 0) > 0)
          key: (current[key] ?? 0) - (previous[key] ?? 0),
    };
  }

  static String _formatBuckets(Map<String, int> buckets) {
    if (buckets.isEmpty) {
      return 'none';
    }
    final sortedEntries = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sortedEntries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(',');
  }
}

class _DebugSnapshot {
  const _DebugSnapshot({
    required this.label,
    required this.reads,
    required this.writes,
    required this.readBuckets,
    required this.writeBuckets,
  });

  final String label;
  final int reads;
  final int writes;
  final Map<String, int> readBuckets;
  final Map<String, int> writeBuckets;
}
