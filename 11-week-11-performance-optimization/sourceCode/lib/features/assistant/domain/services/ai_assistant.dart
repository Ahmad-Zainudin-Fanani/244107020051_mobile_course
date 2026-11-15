/// Kontrak layanan AI yang dipakai lapisan presentasi.
///
/// Implementasi nyata ada di data layer (Gemini), sedangkan test memakai
/// implementasi palsu supaya tidak menyentuh jaringan.
abstract class AiAssistant {
  Stream<String> streamAnswer({
    required String question,
    required String systemPrompt,
  });
}

/// Kesalahan yang sudah diterjemahkan ke bahasa manusia.
///
/// [canRetry] dipakai UI untuk memutuskan apakah tombol coba lagi ditampilkan.
class AssistantException implements Exception {
  const AssistantException(this.message, {this.canRetry = true});

  final String message;
  final bool canRetry;

  @override
  String toString() => message;
}
