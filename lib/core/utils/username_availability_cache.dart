class UsernameAvailabilityCache {
  UsernameAvailabilityCache._();

  static const Duration _ttl = Duration(minutes: 3);
  static final Map<String, _UsernameAvailabilityEntry> _entries =
      <String, _UsernameAvailabilityEntry>{};
  static final Map<String, Future<bool>> _pending = <String, Future<bool>>{};

  static Future<bool> getOrLoad({
    required String normalizedUsername,
    required Future<bool> Function() loader,
  }) {
    final cached = peek(normalizedUsername);
    if (cached != null) {
      return Future<bool>.value(cached);
    }

    final inflight = _pending[normalizedUsername];
    if (inflight != null) {
      return inflight;
    }

    final future = loader()
        .then((value) {
          prime(normalizedUsername: normalizedUsername, isAvailable: value);
          _pending.remove(normalizedUsername);
          return value;
        })
        .catchError((Object error) {
          _pending.remove(normalizedUsername);
          throw error;
        });

    _pending[normalizedUsername] = future;
    return future;
  }

  static bool? peek(String normalizedUsername) {
    final entry = _entries[normalizedUsername];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
      _entries.remove(normalizedUsername);
      return null;
    }
    return entry.isAvailable;
  }

  static void prime({
    required String normalizedUsername,
    required bool isAvailable,
  }) {
    if (normalizedUsername.isEmpty) {
      return;
    }
    _entries[normalizedUsername] = _UsernameAvailabilityEntry(
      isAvailable: isAvailable,
      cachedAt: DateTime.now(),
    );
  }

  static void invalidate(String normalizedUsername) {
    if (normalizedUsername.isEmpty) {
      return;
    }
    _entries.remove(normalizedUsername);
    _pending.remove(normalizedUsername);
  }
}

class _UsernameAvailabilityEntry {
  const _UsernameAvailabilityEntry({
    required this.isAvailable,
    required this.cachedAt,
  });

  final bool isAvailable;
  final DateTime cachedAt;
}
