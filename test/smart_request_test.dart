import 'dart:async';

import 'package:smart_request/smart_request.dart';
import 'package:test/test.dart';

void main() {
  group('smartRequest', () {
    test('returns result on first success', () async {
      final result = await smartRequest<int>(() async => 42);
      expect(result, 42);
    });

    test('timeouts retry and uses fallback', () async {
      final result = await smartRequest<int>(
        () async => await Future<int>.delayed(
            const Duration(milliseconds: 100), () => 1),
        fallback: () async => 7,
        config: const SmartRequestConfig(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 50),
          timeout: Duration(milliseconds: 10),
          jitter: false,
        ),
      );
      expect(result, 7);
    });

    test('non-retryable error uses fallback when provided', () async {
      final result = await smartRequest<int>(
        () async => throw StateError('boom'),
        fallback: () async => 9,
        config: const SmartRequestConfig(),
      );
      expect(result, 9);
    });

    test('non-retryable error rethrows when no fallback', () async {
      await expectLater(
        () => smartRequest<int>(
          () async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('cacheFirst returns cache when present', () async {
      final store = MemoryCacheStore<int>();
      await store.set('k', 5);
      final result = await smartRequest<int>(
        () async => 1,
        cacheConfig: const CacheConfig(policy: CachePolicy.cacheFirst),
        cacheKey: 'k',
        cacheStore: store,
      );
      expect(result, 5);
    });

    test('cacheAndRefresh returns cache and refreshes in background', () async {
      final store = MemoryCacheStore<int>();
      await store.set('k', 10);
      int refreshed = 0;
      final result = await smartRequest<int>(
        () async => 20,
        cacheConfig: const CacheConfig(policy: CachePolicy.cacheAndRefresh),
        cacheKey: 'k',
        cacheStore: store,
        onRefresh: (v) => refreshed = v,
      );
      expect(result, 10); // immediate cached value
      // Allow microtask to run
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(refreshed, 20);
      final cached = await store.get('k');
      expect(cached?.value, 20);
    });
  });
}
