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
  });
}
