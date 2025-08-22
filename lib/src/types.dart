/// A function producing a future result, typically an HTTP/API call.
typedef RequestFunc<T> = Future<T> Function();
