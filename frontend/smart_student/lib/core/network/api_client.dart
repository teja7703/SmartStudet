import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Attaches the signed-in Firebase user's identity to every request so the
    // backend can scope all data to that user. Identity is read live from
    // FirebaseAuth at send time, so it is always the currently logged-in user.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            options.headers['x-firebase-uid'] = user.uid;
            if ((user.email ?? '').isNotEmpty) {
              options.headers['x-user-email'] = user.email;
            }
            if ((user.phoneNumber ?? '').isNotEmpty) {
              options.headers['x-user-phone'] = user.phoneNumber;
            }
          }
          _log(
            'REQUEST',
            '${options.method} ${options.uri}\n'
                'uid=${user?.uid ?? '(none)'} '
                'email=${user?.email ?? '(none)'} '
                'phone=${user?.phoneNumber ?? '(none)'}\n'
                'body=${options.data}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log(
            'RESPONSE',
            '${response.statusCode} ${response.requestOptions.uri}\n'
                'data=${_truncate(response.data)}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _log(
            'ERROR',
            '${error.requestOptions.method} ${error.requestOptions.uri}\n'
                'status=${error.response?.statusCode} '
                'message=${error.message}\n'
                'data=${_truncate(error.response?.data)}',
          );
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  void _log(String tag, String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'API/$tag');
  }

  String _truncate(Object? data, [int max = 800]) {
    final text = data?.toString() ?? 'null';
    return text.length <= max ? text : '${text.substring(0, max)}…';
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
