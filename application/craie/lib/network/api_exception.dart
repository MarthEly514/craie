import 'package:dio/dio.dart';

class ApiException implements Exception{
  final String code;
  final String message;
  final int? statusCode;

  const ApiException(this.code, this.message, [this.statusCode]);

  factory ApiException.fromDio(DioException e){
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return ApiException(
          data['code'] as String? ?? 'UNKNOWN',
          data['message'] as String,
          e.response?.statusCode,
        );
    }
    return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout || 
        DioExceptionType.sendTimeout =>
          const ApiException('TIMEOUT', 'Le serveur met trop de temps à répondre. Réessayez.'),
        DioExceptionType.connectionError =>
          const ApiException('NETWORK', 'Impossible de joindre le serveur. Vérifiez votre connexion.'),
        _ => ApiException('UNKNOWN', 'Une erreur est survenue.', e.response?.statusCode),
      };
  }
  
  @override
  String toString() => message;
}