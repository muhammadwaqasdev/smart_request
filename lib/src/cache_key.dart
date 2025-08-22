import 'dart:convert';

/// Parts used to build a cache key for HTTP-like requests.
class CacheKeyParts {
  final String? method;
  final String url;
  final Map<String, dynamic>? query;
  final Object? body;
  final Map<String, String>? headers;

  /// Only these header names will be included in the key (case-insensitive).
  /// When null or empty, headers are ignored.
  final List<String>? varyHeaders;

  const CacheKeyParts({
    this.method,
    required this.url,
    this.query,
    this.body,
    this.headers,
    this.varyHeaders,
  });
}

/// Builds a cache key string from [CacheKeyParts].
typedef CacheKeyBuilder = String Function(CacheKeyParts parts);

/// Default cache key builder:
/// - method (uppercased)
/// - url
/// - canonicalized query params (sorted keys)
/// - canonicalized body
/// - selected headers (sorted keys) from [varyHeaders]
String defaultCacheKeyBuilder(CacheKeyParts p) {
  final String method = (p.method ?? 'GET').toUpperCase();
  final String url = p.url;
  final Map<String, dynamic> query =
      p.query == null ? const <String, dynamic>{} : _canonicalizeMap(p.query!);

  final Object? body = p.body == null ? null : _canonicalize(p.body);

  final Map<String, String> selectedHeaders = <String, String>{};
  if (p.headers != null && (p.varyHeaders?.isNotEmpty ?? false)) {
    final Set<String> vary = p.varyHeaders!.map((e) => e.toLowerCase()).toSet();
    p.headers!.forEach((k, v) {
      if (vary.contains(k.toLowerCase())) {
        selectedHeaders[k.toLowerCase()] = v;
      }
    });
  }

  final String material = [
    method,
    url,
    jsonEncode(query),
    jsonEncode(body),
    jsonEncode(_canonicalizeMap(selectedHeaders)),
  ].join('|');

  return 'sr:${_djb2(material)}';
}

// ---- helpers ----

String _djb2(String input) {
  int hash = 5381;
  for (final int codeUnit in input.codeUnits) {
    hash = ((hash << 5) + hash) + codeUnit;
  }
  // Ensure positive 32-bit
  hash = hash & 0x7fffffff;
  return hash.toRadixString(16);
}

Object? _canonicalize(Object? value) {
  if (value == null) return null;
  if (value is Map) return _canonicalizeMap(Map<String, dynamic>.from(value));
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value; // primitives
}

Map<String, dynamic> _canonicalizeMap(Map<String, dynamic> input) {
  final List<String> keys = input.keys.map((k) => k.toString()).toList()
    ..sort();
  final Map<String, dynamic> result = <String, dynamic>{};
  for (final String k in keys) {
    result[k] = _canonicalize(input[k]);
  }
  return result;
}
