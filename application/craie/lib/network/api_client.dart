import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response; // here we are hiding because dio and getx both have Response so it can bring confusion
import '../core/constants/app_constants.dart';
import '../shared/services/session_service.dart';
import 'api_exception.dart';
import '../routes/app_routes.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio dio;
  late final Dio _bare;
  Future<bool>? _refreshing;  

  /// [adapter] replaces the real HTTP layer; only tests pass it.
  ApiClient({HttpClientAdapter? adapter}) {
    final options = BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      // Render's free tier can take ~30s to wake up on the first request.
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );
    dio = Dio(options);
    _bare = Dio(options.copyWith());
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      _bare.httpClientAdapter = adapter;
    }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = Get.find<SessionService>().accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },

        onError: (err, handler) async {
          final request = err.requestOptions;
          final isAuthCall =
              request.path == ApiEndpoints.login || request.path == ApiEndpoints.refresh;

          if (err.response?.statusCode != 401 || isAuthCall || request.extra['retried'] == true) {
            return handler.next(err);
          } 
          
          if (await _refreshTokens()) {
            request.extra['retried'] = true;
            try {
              return handler.resolve(await dio.fetch(request));
            } on DioException catch (e) {
              return handler.next(e);
            }
          } 
          
          Get.find<SessionService>().clear();
          Get.offAllNamed(AppRoutes.login);
          handler.next(err);
        },

      ),
    );

    // Never log headers or bodies: they contain tokens and passwords.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestHeader: false, requestBody: false, responseBody: false),
      );
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) =>
      _send(() => dio.post(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) =>
      _send(() => dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _send(() => dio.delete(path));

  Future<bool> _refreshTokens() =>
        _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  
    Future<bool> _doRefresh() async {
      final session = Get.find<SessionService>();
      final token = session.refreshToken;
      if (token == null) return false;

      try {
        final response = await _bare.post(ApiEndpoints.refresh, data: {'refreshToken': token});
        final data = response.data as Map<String, dynamic>;
        session.accessToken = data['accessToken'] as String;
        session.refreshToken = data['refreshToken'] as String;
        return true;
      } on DioException {
        return false;
      }
    }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
