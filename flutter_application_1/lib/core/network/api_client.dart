import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, [this.statusCode, this.details]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final AuthInterceptor _authInterceptor = AuthInterceptor();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_authInterceptor);

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
  }

  void setAuthToken(String? token) {
    _authInterceptor.setToken(token);
  }

  void setOnUnauthorized(VoidCallback onUnauthorized) {
    _authInterceptor.onUnauthorized = onUnauthorized;
  }

  Future<dynamic> get(String url, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(url, queryParameters: queryParams);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient GET Error] $url -> $e');
      rethrow;
    }
  }

  Future<dynamic> post(String url, {dynamic body}) async {
    try {
      final response = await dio.post(url, data: body);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient POST Error] $url -> $e');
      rethrow;
    }
  }

  Future<dynamic> put(String url, {dynamic body}) async {
    try {
      final response = await dio.put(url, data: body);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient PUT Error] $url -> $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String url, {dynamic body, Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.patch(url, data: body, queryParameters: queryParams);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient PATCH Error] $url -> $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String url, {dynamic body}) async {
    try {
      final response = await dio.delete(url, data: body);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient DELETE Error] $url -> $e');
      rethrow;
    }
  }

  Future<dynamic> upload(String url, FormData formData) async {
    try {
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ApiClient UPLOAD Error] $url -> $e');
      rethrow;
    }
  }

  dynamic _extractData(Response response) {
    final data = response.data;
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException('Server is taking too long to respond. Please check connection.', 408);
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException('Unable to connect to the backend server. Please verify the service is running.', 503);
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      String message = 'HTTP error $statusCode';

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('message') && map['message'] != null) {
          message = map['message'].toString();
        } else if (map.containsKey('error') && map['error'] != null) {
          message = map['error'].toString();
        }
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final map = jsonDecode(response.data);
          if (map is Map && map.containsKey('message')) {
            message = map['message'].toString();
          }
        } catch (_) {
          message = response.data.toString();
        }
      }

      switch (statusCode) {
        case 400:
          return ApiException(message.isNotEmpty ? message : 'Invalid request parameters.', statusCode);
        case 401:
          return ApiException(message.isNotEmpty ? message : 'Unauthorized access. Please login again.', statusCode);
        case 403:
          return ApiException(message.isNotEmpty ? message : 'You do not have permission to perform this action.', statusCode);
        case 404:
          return ApiException(message.isNotEmpty ? message : 'Requested resource not found.', statusCode);
        case 409:
          return ApiException(message.isNotEmpty ? message : 'Resource conflict. Already exists.', statusCode);
        case 422:
          return ApiException(message.isNotEmpty ? message : 'Validation error occurred.', statusCode);
        case 500:
        default:
          return ApiException(message.isNotEmpty ? message : 'Internal server error occurred.', statusCode);
      }
    }

    return ApiException(error.message ?? 'An unexpected network error occurred.');
  }
}
