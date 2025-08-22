import 'dart:async';
import 'dart:math' as math;

import 'config.dart';
import 'types.dart';

/// Executes [request] with retry, exponential backoff, and optional [fallback].
///
/// - Respects per-attempt [SmartRequestConfig.timeout]
/// - Retries on errors satisfying [SmartRequestConfig.shouldRetry] (default: all errors)
/// - Applies exponential backoff with optional jitter up to [SmartRequestConfig.maxDelay]
/// - When retries are exhausted and [fallback] is provided, it will be used
///   if [SmartRequestConfig.fallbackOn] returns true (default: true)
Future<T> smartRequest<T>(
  RequestFunc<T> request, {
  RequestFunc<T>? fallback,
  SmartRequestConfig config = const SmartRequestConfig(),
}) async {
  int attempt = 0; // 1-based when used in callbacks
  Duration nextDelay = config.initialDelay;

  while (true) {
    attempt += 1;
    try {
      return await request().timeout(config.timeout);
    } on TimeoutException catch (error, stackTrace) {
      await config.onError?.call(error, stackTrace);

      final bool canRetry = attempt <= config.maxRetries &&
          (config.shouldRetry?.call(error) ?? true);
      if (!canRetry) {
        break; // potentially use fallback below
      }

      final Duration delay = _computeNextDelay(nextDelay, config.jitter);
      await config.onRetry?.call(attempt, delay, error, stackTrace);
      await Future.delayed(delay);

      nextDelay =
          _increaseDelay(nextDelay, config.backoffFactor, config.maxDelay);
      continue;
    } catch (error, stackTrace) {
      await config.onError?.call(error, stackTrace);

      final bool canRetry = attempt <= config.maxRetries &&
          (config.shouldRetry?.call(error) ?? true);
      if (!canRetry) {
        // Give up primary; maybe use fallback
        if (fallback != null && (config.fallbackOn?.call(error) ?? true)) {
          return await fallback().timeout(config.timeout);
        }
        rethrow;
      }

      final Duration delay = _computeNextDelay(nextDelay, config.jitter);
      await config.onRetry?.call(attempt, delay, error, stackTrace);
      await Future.delayed(delay);
      nextDelay =
          _increaseDelay(nextDelay, config.backoffFactor, config.maxDelay);
      continue;
    }
  }

  // Retries exhausted due to TimeoutException path
  if (fallback != null) {
    return await fallback().timeout(config.timeout);
  }
  // If no fallback provided and we reach here, throw a TimeoutException
  throw TimeoutException(
      'smartRequest: retries exhausted after $attempt attempts');
}

Duration _computeNextDelay(Duration current, bool jitter) {
  if (!jitter) return current;
  final int millis = current.inMilliseconds;
  if (millis <= 0) return current;
  final double factor = 0.5 + math.Random().nextDouble(); // [0.5, 1.5)
  final int jittered = (millis * factor).round();
  return Duration(milliseconds: jittered);
}

Duration _increaseDelay(Duration current, double factor, Duration maxDelay) {
  final int nextMs = (current.inMilliseconds * factor)
      .clamp(0, maxDelay.inMilliseconds)
      .toInt();
  return Duration(milliseconds: nextMs);
}
