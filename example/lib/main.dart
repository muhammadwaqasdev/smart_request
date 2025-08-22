import 'package:dio/dio.dart';
import 'package:smart_request/smart_request.dart';

Future<void> main() async {
  final dio = Dio();
  final cache = MemoryCacheStore<Response<dynamic>>();
  final url = 'https://mpe359c3a29a2750bd3b.free.beeceptor.com/success';
  // final url = 'https://mpe359c3a29a2750bd3b.free.beeceptor.com/failed';

  try {
    final response = await smartRequest<Response<dynamic>>(
      () => dio.get(url),
      fallback: () =>
          dio.get('https://mpe359c3a29a2750bd3b.free.beeceptor.com/fallback'),
      config: SmartRequestConfig(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 8),
        backoffFactor: 2.0,
        jitter: true,
        timeout: const Duration(seconds: 5),
        onError: (e, s) => print('Error: $e'),
        onRetry: (attempt, nextDelay, e, s) =>
            print('Retry #$attempt after $nextDelay due to $e'),
        shouldRetry: (_) => true,
      ),
      // Scenario 3: cacheAndRefresh
      cacheConfig: const CacheConfig(
        policy: CachePolicy.cacheAndRefresh,
        ttl: Duration(minutes: 10),
      ),
      cacheKey: 'GET:$url',
      cacheStore: cache,
      onRefresh: (value) {
        print('🔄 Background refreshed cache with latest data: $value');
      },
    );

    print('✅ First return (cache or network): ${response.data}');
  } catch (e) {
    print('❌ Final error: $e');
  }
}
