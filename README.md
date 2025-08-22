# smart_request

Lightweight, dependency-free retries with exponential backoff, timeout, and optional fallback for any async operation.

Works with any HTTP client (Dio, http), GraphQL, gRPC, database calls, or your own async functions.

## Features
- **Retry with backoff**: exponential factor, max delay, and optional jitter
- **Timeout per attempt**: wrap each try in a timeout
- **Fallback support**: switch to an alternate function when retries are exhausted
- **Callbacks**: `onError`, `onRetry`
- **Custom retry predicate**: decide which errors are transient

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_request: ^0.1.0
```

## Quick start (Dio)

```dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:smart_request/smart_request.dart';

Future<void> main() async {
  final dio = Dio();

  try {
    final response = await smartRequest<Response<dynamic>>(
      () => dio.get('https://jsonplaceholder.typicode.com/posts/1'),
      fallback: () => dio.get('https://jsonplaceholder.typicode.com/posts/2'),
      config: SmartRequestConfig(
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 8),
        backoffFactor: 2.0,
        jitter: true,
        timeout: const Duration(seconds: 5),
        onError: (e, s) => print('Error: $e'),
        onRetry: (attempt, nextDelay, e, s) =>
            print('Retry #$attempt after $nextDelay due to $e'),
        // Retry only on timeouts and 5xx from Dio
        shouldRetry: (e) {
          if (e is TimeoutException) return true;
          // dio: handle both DioError (v4) and DioException (v5)
          final typeName = e.runtimeType.toString();
          if (typeName == 'DioError' || typeName == 'DioException') {
            try {
              final status = (e as dynamic).response?.statusCode ?? 0;
              return status >= 500;
            } catch (_) {
              return false;
            }
          }
          return false;
        },
      ),
    );

    print('✅ Response data: ${response.data}');
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

## License

[MIT](LICENSE)
