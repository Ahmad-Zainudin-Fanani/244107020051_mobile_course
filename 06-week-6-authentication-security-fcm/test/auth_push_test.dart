import 'dart:convert';
import 'dart:typed_data';
import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStore extends TokenStore {
  String? access;
  String? refresh;
  bool isCleared = false;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
    isCleared = false;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    isCleared = true;
  }
}

class FakeAuthRepository extends AuthRepository {
  bool shouldFailRefresh = false;

  @override
  Future<String> refresh(String refreshToken) async {
    if (shouldFailRefresh || refreshToken.isEmpty || refreshToken == 'expired') {
      throw Exception('Refresh token tidak valid atau kedaluwarsa');
    }
    return 'mock-access-renewed-test';
  }
}

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('1. Unit Test Parsing Rute Notifikasi (routeFromMessage)', () {
    test('routeFromMessage menangani route kosong dan tanpa slash', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': ''}), '/');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('data payload membawa id pengumuman dan rute dinamis', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });

    test('routeFromMessage menghasilkan rute default saat tipe data bukan string', () {
      expect(routeFromMessage({'route': 12345}), '/');
    });
  });

  group('2. Unit Test Logika Sesi & Masking Keamanan Token', () {
    test('TokenStore maskToken memotong token dengan tepat sesuai OWASP', () {
      expect(TokenStore.maskToken(null), '(tidak ada token)');
      expect(TokenStore.maskToken(''), '(tidak ada token)');
      expect(TokenStore.maskToken('short_token'), 'short_token...');
      expect(
        TokenStore.maskToken('mock-access-for-mahasiswa@campus.ac.id-123456789'),
        'mock-access-...',
      );
    });

    test('FakeTokenStore menyimpan dan membaca sesi', () async {
      final store = FakeTokenStore();
      await store.save(access: 'acc_123', refresh: 'ref_456');

      expect(await store.readAccess(), 'acc_123');
      expect(await store.readRefresh(), 'ref_456');
    });

    test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () async {
      final store = FakeTokenStore()..refresh = '';
      final needsLogin = (await store.readRefresh() ?? '').isEmpty;
      expect(needsLogin, isTrue);

      await store.clear();
      expect(store.isCleared, isTrue);
      expect(await store.readAccess(), isNull);
    });
  });

  group('3. Unit Test ApiErrorMapper (Refactoring Challenge 3)', () {
    test('Memetakan HTTP 401 ke pesan sesi berakhir', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final message = ApiErrorMapper.mapDioError(error);
      expect(message, contains('Sesi autentikasi Anda telah berakhir (401)'));
    });

    test('Memetakan Connection Error / Offline', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final message = ApiErrorMapper.mapDioError(error);
      expect(message, contains('offline'));
    });
  });

  group('4. Unit Test Dio Interceptor Auto-Refresh 401', () {
    test('Dio me-refresh token dan mengulang request saat menerima 401', () async {
      final store = FakeTokenStore()
        ..access = 'old-access-token'
        ..refresh = 'valid-refresh-token';
      final repo = FakeAuthRepository();

      var sessionExpiredTriggered = false;
      final dio = buildApiClient(
        store,
        repo,
        baseUrl: 'https://campus.test',
        onSessionExpired: () => sessionExpiredTriggered = true,
      );

      var attempt = 0;
      dio.httpClientAdapter = MockHttpAdapter((options) async {
        attempt++;
        if (attempt == 1) {
          // Response pertama 401 Unauthorized
          return ResponseBody.fromString(
            jsonEncode({'error': 'Unauthorized'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        // Response kedua (setelah refresh) 200 OK
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final response = await dio.get('/profile');
      expect(response.statusCode, 200);
      expect(response.data['success'], isTrue);
      expect(attempt, 2);
      expect(await store.readAccess(), 'mock-access-renewed-test');
      expect(sessionExpiredTriggered, isFalse);
    });

    test('Dio membersihkan sesi dan memanggil callback saat refresh token kedaluwarsa', () async {
      final store = FakeTokenStore()
        ..access = 'old-access-token'
        ..refresh = 'expired';
      final repo = FakeAuthRepository()..shouldFailRefresh = true;

      var sessionExpiredTriggered = false;
      final dio = buildApiClient(
        store,
        repo,
        baseUrl: 'https://campus.test',
        onSessionExpired: () => sessionExpiredTriggered = true,
      );

      dio.httpClientAdapter = MockHttpAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'error': 'Unauthorized'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      try {
        await dio.get('/profile');
        fail('Harus melempar DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }

      expect(store.isCleared, isTrue);
      expect(sessionExpiredTriggered, isTrue);
    });
  });
}
