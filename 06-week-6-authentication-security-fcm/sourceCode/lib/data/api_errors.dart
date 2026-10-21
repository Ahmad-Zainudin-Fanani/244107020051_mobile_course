import 'package:dio/dio.dart';

class ApiErrorMapper {
  /// Maps DioException to a user-friendly Indonesian message.
  static String mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server batas waktu berakhir (timeout). Silakan periksa jaringan Anda.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Sesi autentikasi Anda telah berakhir (401). Silakan login kembali.';
        } else if (statusCode == 403) {
          return 'Anda tidak memiliki hak akses ke layanan ini (403).';
        } else if (statusCode == 404) {
          return 'Layanan atau data yang diminta tidak ditemukan (404).';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Terjadi gangguan pada server kampus ($statusCode). Silakan coba lagi nanti.';
        }
        return 'Terjadi kesalahan respons server (${statusCode ?? "unknown"}).';

      case DioExceptionType.cancel:
        return 'Permintaan ke server dibatalkan.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server (offline). Pastikan koneksi internet aktif.';

      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan server tidak valid.';

      case DioExceptionType.unknown:
      default:
        return error.message?.isNotEmpty == true
            ? 'Terjadi kesalahan jaringan: ${error.message}'
            : 'Terjadi kesalahan yang tidak terduga pada koneksi server.';
    }
  }
}
