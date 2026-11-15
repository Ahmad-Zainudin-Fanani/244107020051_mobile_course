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
    // Secara default mengembalikan list kosong sampai fetchComments dipanggil
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
