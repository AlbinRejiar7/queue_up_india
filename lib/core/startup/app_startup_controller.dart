import 'dart:async';

abstract final class AppStartupController {
  static Completer<void> _readyCompleter = Completer<void>();

  static Future<void> get ready => _readyCompleter.future;

  static bool get isReady => _readyCompleter.isCompleted;

  static void begin() {
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }
  }

  static void markReady() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }
}
