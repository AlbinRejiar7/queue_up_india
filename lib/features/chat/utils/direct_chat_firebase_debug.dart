import 'package:flutter/foundation.dart';

abstract final class DirectChatFirebaseDebug {
  static int _estimatedReads = 0;
  static int _writes = 0;

  static void read({
    required String source,
    required int count,
    String? detail,
  }) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    _estimatedReads += count;
    debugPrint(
      '[DirectChatFirebase] READ +$count total=$_estimatedReads '
      'source=$source${_suffix(detail)}',
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
    _writes += count;
    debugPrint(
      '[DirectChatFirebase] WRITE +$count total=$_writes '
      'source=$source${_suffix(detail)}',
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
}
