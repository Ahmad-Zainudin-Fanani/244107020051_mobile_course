import 'package:dio/dio.dart';
import 'auth_repository.dart';
import 'token_store.dart';

Dio buildApiClient(
  TokenStore store,
  AuthRepository auth, {
  String baseUrl = 'https://example-campus-api.test',
  void Function()? onSessionExpired,
}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final access = await store.readAccess();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      // Refresh otomatis satu kali saat HTTP 401
      if (e.response?.statusCode == 401) {
        // Hindari loop tak terbatas bila request retry sendiri mengembalikan 401
        final isRetry = e.requestOptions.extra['isRetry'] == true;
        if (isRetry) {
          await store.clear();
          onSessionExpired?.call();
          return handler.next(e);
        }

        final refresh = await store.readRefresh();
        if (refresh == null || refresh.isEmpty) {
          await store.clear();
          onSessionExpired?.call();
          return handler.next(e);
        }

        try {
          final renewed = await auth.refresh(refresh);
          await store.save(access: renewed, refresh: refresh);

          final retryOptions = e.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $renewed';
          retryOptions.extra['isRetry'] = true;

          final retryResponse = await dio.fetch(retryOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Bila refresh token kedaluwarsa atau gagal, bersihkan sesi
          await store.clear();
          onSessionExpired?.call();
        }
      }
      handler.next(e);
    },
  ));

  return dio;
}
