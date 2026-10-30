import 'package:dio/dio.dart';

/// Reserved for a future remote repository; demo mode never makes API calls.
Dio createApiClient(Uri baseUrl) {
  if (baseUrl.scheme != 'https' ||
      baseUrl.host.isEmpty ||
      baseUrl.userInfo.isNotEmpty) {
    throw ArgumentError('API base URL must use HTTPS without credentials');
  }
  return Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    )
    ..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          handler.next(error.copyWith(error: NetworkFailure.fromDio(error)));
        },
      ),
    );
}

class NetworkFailure implements Exception {
  const NetworkFailure(this.message);
  final String message;
  factory NetworkFailure.fromDio(DioException e) =>
      NetworkFailure(switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => 'Kết nối quá chậm. Vui lòng thử lại.',
        DioExceptionType.cancel => 'Yêu cầu đã được hủy.',
        DioExceptionType.badResponse => 'Dịch vụ tạm thời không khả dụng.',
        _ => 'Không thể kết nối. Hãy kiểm tra Internet.',
      });
}
