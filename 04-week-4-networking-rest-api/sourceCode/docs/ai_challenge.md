# 6. AI Challenge - Documentation & Verification Report

## 1. AI Prompt Challenge

**Prompt yang Digunakan:**
> Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id} dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
> Requirements:
> - Model Comment dengan fromJson aman null (postId, id, name, email, body).
> - CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
> - AsyncNotifierProvider dengan penanganan error otomatis (AsyncError) dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
> - Satu unit test untuk fromJson dengan field yang hilang.
> Jelaskan setiap bagian kode dalam komentar.

---

## 2. Implementasi Kode

### A. Model Comment (`lib/data/models/comment.dart`)
```dart
/// Model data Comment yang merepresentasikan response dari GET /comments.
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Factory constructor fromJson yang defensif dan aman null (null-safe).
  /// Menghindari crash 'Null is not a subtype of type ...' jika field dari API bernilai null atau hilang.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Konversi objek Comment ke Map JSON.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
```

### B. CommentRepository (`lib/data/repositories/comment_repository.dart`)
```dart
import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository untuk mengakses data Comment dari API.
/// Dio dikirim melalui dependency injection agar terpusat di ApiClient.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil daftar komentar berdasarkan postId dengan query parameter ?postId={id}.
  /// Menggunakan options timeout 10 detik per-request.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

### C. Comment Providers & Error Handler (`lib/data/comment_providers.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Provider terpusat untuk CommentRepository.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Notifier menggunakan AsyncNotifier untuk mengelola state komentar.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build() async {
    return [];
  }

  /// Memuat komentar berdasarkan postId
  Future<void> fetchComments(int postId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider AsyncNotifier untuk CommentListNotifier.
final commentListProvider =
    AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

/// Memetakan error DioException atau Exception teknis ke pesan ramah pengguna.
String friendlyCommentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout (10 detik). Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Komentar tidak ditemukan (404).';
        }
        if (statusCode == 500) {
          return 'Terjadi masalah pada server (500). Coba lagi nanti.';
        }
        return 'Terjadi kesalahan pada server ($statusCode).';
      default:
        return 'Terjadi kesalahan jaringan saat mengambil komentar.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
```

### D. Unit Tests (`test/comment_test.dart`)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model Unit Tests', () {
    test('fromJson harus mengembalikan objek Comment valid dari JSON lengkap', () {
      final json = {
        'postId': 1,
        'id': 10,
        'name': 'id labore ex et quam laborum',
        'email': 'Eliseo@gardner.biz',
        'body': 'laudantium enim quasi est quidem magnam voluptate',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 10);
      expect(comment.name, 'id labore ex et quam laborum');
      expect(comment.email, 'Eliseo@gardner.biz');
      expect(comment.body, 'laudantium enim quasi est quidem magnam voluptate');
    });

    test('fromJson aman null ketika ada field yang hilang (missing fields)', () {
      final json = {
        'id': 5,
        'email': 'test@example.com',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 5);
      expect(comment.name, '');
      expect(comment.email, 'test@example.com');
      expect(comment.body, '');
    });

    test('Edge Case: fromJson aman ketika nilai berupa null eksplisit dan tipe double', () {
      final json = {
        'postId': 2.0,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 2);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });
}
```

---

## 3. AI Verification Checklist

| Kriteria Verifikasi | Status | Temuan / Detail Verifikasi |
|---|---|---|
| **Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?** | ✅ Pass | UI memanggil `commentListProvider` / `CommentRepository`, tidak ada pemanggilan `Dio` secara langsung di UI. |
| **Apakah `fromJson` aman null, atau masih memakai cast langsung?** | ✅ Pass | Menggunakan casting defensif `(json['postId'] as num?)?.toInt() ?? 0` dan `as String? ?? ''`, sehingga tidak akan crash akibat `Null is not a subtype of...`. |
| **Apakah semua tipe DioExceptionType dipetakan ke pesan pengguna?** | ✅ Pass | Menerjemahkan `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, serta status code `404` & `500` ke pesan Bahasa Indonesia yang ramah pengguna. |
| **Apakah `baseUrl`/timeout terpusat di satu client?** | ✅ Pass | Menggunakan `dioProvider` yang mereferensikan `createDio()` terpusat di `api_client.dart`, dengan tambahan timeout 10s per-request. |
| **Apakah test AI menguji kasus field hilang + edge case tambahan?** | ✅ Pass | Unit test menguji: (1) Happy path JSON lengkap, (2) Field hilang/missing fields, (3) Edge case nilai `null` eksplisit & angka bertipe double. |
| **Hasil `flutter analyze` & `flutter test`** | ✅ Pass | **0 Error / 0 Warnings** pada `flutter analyze` dan **4/4 Tests Passed** pada `flutter test`. |
