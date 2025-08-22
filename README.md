[![Pub Version](https://img.shields.io/pub/v/smart_request?logo=dart&logoColor=white)](https://pub.dev/packages/smart_request/)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/smart_request)](https://pub.dev/packages/smart_request/)
[![License](https://img.shields.io/github/license/muhammadwaqasdev/smart_request)](https://github.com/muhammadwaqasdev/smart_request/blob/main/LICENSE)

# Smart Request

Lightweight, dependency-free retries with exponential backoff, timeout, and optional fallback for any async operation.

Works with any HTTP client (Dio, http), GraphQL, gRPC, database calls, or your own async functions.

## Features
- **Retry with backoff**: exponential factor, max delay, and optional jitter
- **Timeout per attempt**: wrap each try in a timeout
- **Fallback support**: switch to an alternate function when retries are exhausted
- **Callbacks**: `onError`, `onRetry`
- **Custom retry predicate**: decide which errors are transient
- **Built-in offline cache manager**: `noCache`, `cacheFirst`, `cacheAndRefresh`

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_request: ^0.1.0
```

## Quick start (Dio) with cache

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:smart_request/smart_request.dart';

Future<void> main() async {
  final dio = Dio();
  final cache = MemoryCacheStore<Response<dynamic>>();
  const url = 'https://jsonplaceholder.typicode.com/posts/1';

  try {
    final response = await smartRequest<Response<dynamic>>(
      () => dio.get(url),
      fallback: () => dio.get('https://jsonplaceholder.typicode.com/posts/2'),
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
      // Scenario 3: return cache and refresh in background
      cacheConfig: const CacheConfig(
        policy: CachePolicy.cacheAndRefresh,
        ttl: Duration(minutes: 10),
      ),
      cacheKey: 'GET:$url',
      cacheStore: cache,
      onRefresh: (value) {
        print('🔄 Background refreshed cache with latest data');
      },
    );

    print('✅ First return (cache or network): ${response.data}');
  } catch (e) {
    print('❌ Final error: $e');
  }
}
```

## API

```dart
typedef RequestFunc<T> = Future<T> Function();

Future<T> smartRequest<T>(
  RequestFunc<T> request, {
  RequestFunc<T>? fallback,
  SmartRequestConfig config = const SmartRequestConfig(),
  CacheConfig cacheConfig = const CacheConfig(),
  String? cacheKey,
  CacheStore<T>? cacheStore,
  FutureOr<void> Function(T value)? onRefresh,
});
```

### SmartRequestConfig

| Field         | Type                                                            | Default              | Description |
|---------------|-----------------------------------------------------------------|----------------------|-------------|
| maxRetries    | int                                                             | 3                    | Number of retries. Total attempts = 1 + maxRetries. |
| initialDelay  | Duration                                                        | 1s                   | Delay before the first retry. |
| maxDelay      | Duration                                                        | 30s                  | Maximum backoff delay cap. |
| backoffFactor | double                                                          | 2.0                  | Exponential growth factor for delay. |
| jitter        | bool                                                            | true                 | Adds ±50% randomness to each delay. |
| timeout       | Duration                                                        | 30s                  | Per-attempt timeout (applies to fallback too). |
| onError       | FutureOr<void> Function(Object error, StackTrace stackTrace)?   | null                 | Called on every error before retry decision. |
| onRetry       | FutureOr<void> Function(int attempt, Duration nextDelay, Object error, StackTrace stackTrace)? | null | Called before waiting for the next retry. |
| shouldRetry   | bool Function(Object error)?                                    | true (all errors)    | Decides if an error is retryable. |
| fallbackOn    | bool Function(Object error)?                                    | true                 | Whether to use fallback when retries are exhausted. |

## Example app

See `example/lib/main.dart` for a runnable example using Dio.

## CacheConfig

| Field  | Type          | Default  | Description |
|--------|---------------|----------|-------------|
| policy | CachePolicy   | noCache  | Caching strategy: `noCache`, `cacheFirst`, `cacheAndRefresh`. |
| ttl    | Duration?     | null     | Time-to-live for entries. `null` means never expire. |

## License

[MIT](LICENSE)
