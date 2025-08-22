import 'dart:async';

/// Configuration for [smartRequest].
///
/// Works with any async client (Dio, http, GraphQL, gRPC, DB, etc.).
/// Supports exponential backoff with optional jitter, configurable retry
/// predicates, and a fallback request.
class SmartRequestConfig {
  /// Maximum number of retry attempts before giving up.
  ///
  /// Example: with [maxRetries] = 3, the request may run up to 4 times
  /// (1 initial + 3 retries).
  final int maxRetries;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay cap between retries.
  final Duration maxDelay;

  /// Exponential factor applied to the delay on each retry.
  ///
  /// For example, with factor 2.0 and initial delay 1s, retries wait roughly
  /// 1s, 2s, 4s, ... up to [maxDelay].
  final double backoffFactor;

  /// Whether to apply jitter (+/- 50%) to each retry delay to reduce thundering herd issues.
  final bool jitter;

  /// Per-attempt timeout. Each request (and fallback) is wrapped with this timeout.
  final Duration timeout;

  /// Optional callback invoked on any error (before retry decision).
  final FutureOr<void> Function(Object error, StackTrace stackTrace)? onError;

  /// Predicate that decides whether an error is retryable.
  ///
  /// Defaults to retrying on all errors.
  final bool Function(Object error)? shouldRetry;

  /// Callback invoked before a retry delay is awaited.
  /// Provides the attempt number (1-based), planned delay, and the triggering error.
  final FutureOr<void> Function(
          int attempt, Duration nextDelay, Object error, StackTrace stackTrace)?
      onRetry;

  /// Predicate that decides whether to use [fallback] when retries are exhausted.
  ///
  /// Defaults to true for any error.
  final bool Function(Object error)? fallbackOn;

  const SmartRequestConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffFactor = 2.0,
    this.jitter = true,
    this.timeout = const Duration(seconds: 30),
    this.onError,
    this.shouldRetry,
    this.onRetry,
    this.fallbackOn,
  })  : assert(maxRetries >= 0, 'maxRetries must be >= 0'),
        assert(backoffFactor >= 1.0, 'backoffFactor must be >= 1.0');
}
