import 'dart:async';

import 'package:dio/dio.dart';
import 'package:smart_request/smart_request.dart';

Future<void> main() async {
  final dio = Dio();

  try {
    final response = await smartRequest<Response<dynamic>>(
      () => dio.get('https://mpe359c3a29a2750bd3b.free.beeceptor.com/call'),
      fallback: () =>
          dio.get('https://mpe359c3a29a2750bd3b.free.beeceptor.com/fallback'),
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
      ),
    );

    print('✅ Response data: ${response.data}');
  } catch (e) {
    print('❌ Final error: $e');
  }
}
