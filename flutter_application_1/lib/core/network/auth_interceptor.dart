import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  String? _token;
  VoidCallback? onUnauthorized;

  void setToken(String? token) {
    _token = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null && _token!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    options.headers['Accept'] = 'application/json';
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] 401 Unauthorized on: ${err.requestOptions.path}');
      onUnauthorized?.call();
    }
    return super.onError(err, handler);
  }
}
