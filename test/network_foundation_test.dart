import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/core/services/api_exceptions.dart';
import 'package:dio/dio.dart';

void main() {
  group('ApiException Tests', () {
    test('maps Spring Boot error JSON payload correctly', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        data: {
          'message': 'Invalid email format',
          'error': 'Bad Request',
        },
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.statusCode, 400);
      expect(exception.message, 'Invalid email format');
      expect(exception.error, 'Bad Request');
    });

    test('maps 401 Unauthorized default message', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 401,
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: response,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.statusCode, 401);
      expect(exception.message, contains('Session expired'));
    });

    test('maps connection timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioException);
      expect(exception.message, contains('timed out'));
    });
  });
}
