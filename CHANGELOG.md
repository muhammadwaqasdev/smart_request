## 0.2.0

- Added offline cache manager with three strategies:
    - `noCache` – always call API
    - `cacheFirst` – return from cache if found, otherwise call API
    - `cacheAndRefresh` – return cache immediately and refresh in background
- Introduced customizable cache key builder (based on method, URL, query, body, and headers)
- Added `onRefresh` callback for background refresh
- Example updated with `MemoryCacheStore`
- Internal refactor for better extensibility

## 0.1.1

- Updated Readme file

## 0.1.0

- First public release
- Pure Dart (no Flutter dependency)
- Exponential backoff with optional jitter
- Retry predicate and callbacks (`onError`, `onRetry`)
- Optional fallback request when retries are exhausted
