import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class DefaultException extends ApiException {
  DefaultException([String message = 'An unexpected error occurred.']) : super(message);
}

class NoInternetException extends ApiException {
  NoInternetException() : super('No Internet Connection. Please check your network.');
}

class ServerException extends ApiException {
  ServerException(super.message, {super.statusCode});
}

class TimeoutException extends ApiException {
  TimeoutException() : super('Connection Timeout. Please try again later.');
}

class AppErrorHandler {
  static ApiException handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return TimeoutException();
    } else if (error.type == DioExceptionType.connectionError ||
        error.error is NoInternetException) {
      return NoInternetException();
    } else if (error.response != null) {
      // Look for custom API message format, else default message string
      final data = error.response?.data;
      String errorMessage = 'Server Error: ${error.response?.statusCode}';

      if (data is Map) {
        if (data.containsKey('errors') &&
            data['errors'] is List &&
            (data['errors'] as List).isNotEmpty) {
          final firstError = data['errors'][0];
          if (firstError is Map && firstError.containsKey('message')) {
            errorMessage = '${data['message'] ?? 'Error'}: ${firstError['message']}';
          } else {
            errorMessage = data['message']?.toString() ?? errorMessage;
          }
        } else if (data.containsKey('message')) {
          errorMessage = data['message']?.toString() ?? errorMessage;
        }
      }
      return ServerException(errorMessage, statusCode: error.response?.statusCode);
    } else {
      return DefaultException('Unexpected error occurred: ${error.message}');
    }
  }
}
