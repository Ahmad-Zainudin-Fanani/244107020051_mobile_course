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
