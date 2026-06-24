/// A friendly, typed error surfaced by the API layer. `status` is the HTTP code
/// (0 = network/timeout/offline). UI shows `message`; callers can branch on
/// `status` (e.g. 409 slot-clash, 400 validation).
class ApiException implements Exception {
  final int status;
  final String message;
  final Object? details;

  const ApiException(this.status, this.message, [this.details]);

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;
  bool get isForbidden => status == 403;
  bool get isConflict => status == 409;

  @override
  String toString() => 'ApiException($status): $message';
}
