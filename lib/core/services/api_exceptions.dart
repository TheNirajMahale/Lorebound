/// Standardized API exception model mapped from Spring Boot error responses.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.details,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';

  /// Creates an [ApiException] from a Dio error response or network failure.
  factory ApiException.fromDioException(dynamic dioError) {
    if (dioError == null) {
      return const ApiException(message: 'An unknown error occurred');
    }

    // If already normalized
    if (dioError is ApiException) return dioError;

    final response = dioError.response;
    final statusCode = response?.statusCode;
    String message = 'Network request failed';
    String? error;
    Map<String, dynamic>? details;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      // Spring Boot default error payload or custom GlobalExceptionHandler structure
      message = data['message'] as String? ?? 
                data['error'] as String? ?? 
                'Server responded with status $statusCode';
      error = data['error'] as String?;
      details = data;
    } else if (response?.data is String && (response!.data as String).isNotEmpty) {
      message = response.data as String;
    } else {
      switch (dioError.type.toString()) {
        case 'DioExceptionType.connectionTimeout':
        case 'DioExceptionType.sendTimeout':
        case 'DioExceptionType.receiveTimeout':
          message = 'Connection timed out. Please check your network connection.';
          break;
        case 'DioExceptionType.connectionError':
          message = 'Unable to connect to Lorekeeper server. Check server address or WiFi.';
          break;
        case 'DioExceptionType.cancel':
          message = 'Request was cancelled.';
          break;
        default:
          if (statusCode == 401) {
            message = 'Session expired. Please log in again.';
          } else if (statusCode == 403) {
            message = 'Access denied.';
          } else if (statusCode == 404) {
            message = 'Requested resource not found.';
          } else if (statusCode != null && statusCode >= 500) {
            message = 'Lorekeeper server encountered an error ($statusCode).';
          }
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      error: error,
      details: details,
    );
  }
}
