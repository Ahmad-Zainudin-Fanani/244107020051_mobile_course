import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/services/ai_assistant.dart';

/// Klien Gemini Interactions API dengan streaming SSE.
///
/// Satu instance mewakili satu API key. Percakapan tidak dikirim ulang sebagai
/// riwayat: setiap pertanyaan berdiri sendiri supaya data yang keluar dari
/// perangkat tetap minimal.
class GeminiAssistant implements AiAssistant {
  GeminiAssistant({
    required this.apiKey,
    http.Client? client,
    this.model = defaultModel,
    this.timeout = const Duration(seconds: 30),
    this.maxOutputTokens = 512,
  }) : _client = client ?? http.Client();

  /// Model stabil termurah saat fitur ini dibuat.
  ///
  /// Contoh di modul memakai `gemini-pro`, yang sudah tidak tersedia, dan
  /// `gemini-2.5-flash` yang sudah deprecated. Lihat `docs/ai-log.md`.
  static const defaultModel = 'gemini-3.5-flash-lite';

  static final _endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse',
  );

  final String apiKey;
  final String model;
  final Duration timeout;
  final int maxOutputTokens;
  final http.Client _client;

  @override
  Stream<String> streamAnswer({
    required String question,
    required String systemPrompt,
  }) async* {
    final request = http.Request('POST', _endpoint)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'x-goog-api-key': apiKey,
      })
      ..body = jsonEncode({
        'model': model,
        'input': question,
        'stream': true,
        // Jangan simpan percakapan di sisi Google; konteks tetap di perangkat.
        'store': false,
        'system_instruction': systemPrompt,
        'generation_config': {'max_output_tokens': maxOutputTokens},
      });

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const AssistantException(
        'Layanan AI tidak merespons dalam 30 detik. Coba lagi.',
      );
    } on SocketException {
      throw const AssistantException(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
      );
    } on http.ClientException {
      throw const AssistantException('Koneksi ke layanan AI gagal. Coba lagi.');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw _mapHttpFailure(response.statusCode, body);
    }

    var receivedText = false;
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(timeout);

    try {
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;

        final Map<String, dynamic> event;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map<String, dynamic>) continue;
          event = decoded;
        } on FormatException {
          // Satu event rusak tidak boleh membuang seluruh jawaban.
          continue;
        }

        if (event['event_type'] == 'error') {
          final error = event['error'];
          final message = error is Map ? error['message'] : null;
          throw AssistantException(
            message is String && message.isNotEmpty
                ? 'AI mengembalikan error: $message'
                : 'AI mengembalikan error. Coba lagi.',
          );
        }

        if (event['event_type'] != 'step.delta') continue;
        final delta = event['delta'];
        if (delta is! Map) continue;
        if (delta['type'] != 'text') continue;

        final text = delta['text'];
        if (text is String && text.isNotEmpty) {
          receivedText = true;
          yield text;
        }
      }
    } on TimeoutException {
      throw const AssistantException(
        'Jawaban AI terputus karena terlalu lama. Coba lagi.',
      );
    } on http.ClientException {
      throw const AssistantException('Koneksi ke layanan AI terputus.');
    }

    if (!receivedText) {
      throw const AssistantException(
        'AI tidak mengembalikan teks. Coba ubah pertanyaan Anda.',
      );
    }
  }

  AssistantException _mapHttpFailure(int statusCode, String body) {
    final detail = _extractErrorMessage(body);
    switch (statusCode) {
      case 400:
        return AssistantException(
          'Permintaan ditolak (HTTP 400). Coba pertanyaan yang lebih singkat.'
          '${detail.isEmpty ? '' : ' Detail: $detail'}',
        );
      case 401:
      case 403:
        return AssistantException(
          'API key ditolak (HTTP $statusCode). '
          'Periksa kembali key di Pengaturan.',
          canRetry: false,
        );
      case 404:
        return const AssistantException(
          'Model AI tidak ditemukan. Perbarui aplikasi atau hubungi pengembang.',
          canRetry: false,
        );
      case 429:
        return const AssistantException(
          'Kuota AI habis (HTTP 429). Tunggu beberapa saat lalu coba lagi.',
        );
      default:
        if (statusCode >= 500) {
          return AssistantException(
            'Layanan AI sedang sibuk (HTTP $statusCode). Coba lagi nanti.',
          );
        }
        return AssistantException('Gagal memanggil AI (HTTP $statusCode).');
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          final message = (error['message'] as String).trim();
          return message.length > 120
              ? '${message.substring(0, 120)}…'
              : message;
        }
      }
    } on FormatException {
      // Body bukan JSON; tidak ada detail yang bisa ditampilkan.
    }
    return '';
  }

  /// Menutup koneksi HTTP yang dipegang klien ini.
  void dispose() => _client.close();
}
