import 'dart:async';

/// Cache policy for cached smart requests.
enum CachePolicy {
  /// Do not use cache. Always hit the network.
  noCache,

  /// Return cache if available; otherwise fetch from network and save.
  cacheFirst,

  /// Stale-while-revalidate:
  /// - If cache exists, return it immediately and refresh in background.
  /// - If cache missing, fetch from network and save.
  cacheAndRefresh,
}

/// In-memory cache entry that stores a value and its insertion time.
class CacheEntry<T> {
  final T value;
  final DateTime insertedAt;

  CacheEntry(this.value) : insertedAt = DateTime.now();

  bool isExpired(Duration? ttl) {
    if (ttl == null) return false;
    return DateTime.now().difference(insertedAt) > ttl;
  }
}

/// Abstraction for a simple key-value cache store.
abstract class CacheStore<T> {
  FutureOr<CacheEntry<T>?> get(String key);
  FutureOr<void> set(String key, T value);
  FutureOr<void> remove(String key);
  FutureOr<void> clear();
}

/// In-memory cache store using a Map. Suitable as a default.
class MemoryCacheStore<T> implements CacheStore<T> {
  final Map<String, CacheEntry<T>> _map = <String, CacheEntry<T>>{};

  @override
  FutureOr<CacheEntry<T>?> get(String key) => _map[key];

  @override
  FutureOr<void> set(String key, T value) {
    _map[key] = CacheEntry<T>(value);
  }

  @override
  FutureOr<void> remove(String key) => _map.remove(key);

  @override
  FutureOr<void> clear() {
    _map.clear();
  }
}

/// Configuration for caching behavior.
class CacheConfig {
  final CachePolicy policy;

  /// Time-to-live for cached entries. If null, entries never expire.
  final Duration? ttl;

  const CacheConfig({
    this.policy = CachePolicy.noCache,
    this.ttl,
  });
}
