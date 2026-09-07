class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;
  final bool isCertificateError;
  final bool isNetworkError;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
    this.isCertificateError = false,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}
