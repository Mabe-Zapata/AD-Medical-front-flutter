/// Why an operation failed. Mirrors the error kinds of the Angular app so both frontends
/// treat the same failures the same way.
enum ErrorKind {
  invalidCredentials,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  network,
  unavailable,

  /// A staff account tried to use the patient portal.
  notPatient,
  unknown,
}

/// Error raised by the domain or data layers. The UI decides how to word it.
class AppError implements Exception {
  const AppError(this.kind, this.message, {this.correlationId, this.status});

  final ErrorKind kind;

  /// Technical detail (English, as the backend sends it). Never shown as the main message.
  final String message;

  /// Correlation id the backend returned, so support can find the request in the logs.
  final String? correlationId;
  final int? status;

  @override
  String toString() => 'AppError($kind, $message)';
}
