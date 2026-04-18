import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_exceptions.dart';
import 'network_info.dart';

class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  ApiClient({
    required Dio dio,
    required NetworkInfo networkInfo,
  })  : _dio = dio,
        _networkInfo = networkInfo {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options = BaseOptions(
      baseUrl: 'https://quickplate-backend-z3j0.onrender.com/api/v1', // Replace with dev/prod url
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Debug logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }

    // Auth and Network Connectivity Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always check connectivity before firing the physical request
          if (!await _networkInfo.isConnected) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: NoInternetException(),
                type: DioExceptionType.connectionError,
              ),
            );
          }

          // TODO: Inject Authorization Tokens if valid user is logged in
          // options.headers['Authorization'] = 'Bearer user_token';

          return handler.next(options);
        },
        onError: (DioException e, handler) {
           // Can globally catch 401 Unauthorized here and trigger router logout
           return handler.next(e);
        }
      ),
    );
  }

  // --- HTTP Methods ---

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw AppErrorHandler.handleDioError(e);
    } catch (e) {
      throw DefaultException(e.toString());
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw AppErrorHandler.handleDioError(e);
    } catch (e) {
      throw DefaultException(e.toString());
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      throw AppErrorHandler.handleDioError(e);
    } catch (e) {
      throw DefaultException(e.toString());
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response;
    } on DioException catch (e) {
      throw AppErrorHandler.handleDioError(e);
    } catch (e) {
      throw DefaultException(e.toString());
    }
  }
}
