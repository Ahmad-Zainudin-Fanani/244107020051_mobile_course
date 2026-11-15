import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../notes/presentation/providers/notes_providers.dart';
import '../../data/api_key_store.dart';
import '../../data/gemini_assistant.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/services/ai_assistant.dart';
import '../../domain/usecases/build_system_prompt.dart';

/// Penyimpanan API key. Diganti dengan fake saat test.
final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) {
  return SecureApiKeyStore();
});

/// Klien HTTP bersama. Ditutup saat container dibuang.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Membuat layanan AI untuk satu API key.
///
/// Berupa fungsi, bukan instance, karena key baru diketahui saat pengguna
/// mengirim pesan (bisa saja baru diisi di Pengaturan).
typedef AiAssistantFactory = AiAssistant Function(String apiKey);

final aiAssistantFactoryProvider = Provider<AiAssistantFactory>((ref) {
  final client = ref.watch(httpClientProvider);
  return (apiKey) => GeminiAssistant(apiKey: apiKey, client: client);
});

/// Batas permintaan per sesi untuk menahan biaya API.
final chatRequestLimitProvider = Provider<int>((ref) => 20);

/// Status apakah API key sudah tersimpan. Dipakai halaman Pengaturan.
final apiKeyStatusProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(apiKeyStoreProvider).read();
  return key != null;
});

/// Pilihan pengguna: sertakan judul catatan sebagai konteks atau tidak.
///
/// Default mati supaya tidak ada data pengguna yang keluar dari perangkat
/// tanpa persetujuan eksplisit.
class IncludeNotesContextNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final includeNotesContextProvider =
    NotifierProvider<IncludeNotesContextNotifier, bool>(
      IncludeNotesContextNotifier.new,
    );

/// Judul catatan yang benar-benar dikirim sebagai konteks.
///
/// `notesProvider` bersifat autoDispose, sedangkan `MainLayout` hanya
/// membangun satu halaman pada satu waktu. Membacanya sekali saat tombol
/// kirim ditekan bisa mendapat state loading, sehingga judul tidak pernah
/// terkirim. Provider ini memantau daftar selama halaman Asisten hidup dan
/// hanya mengembalikan judul saat pengguna menyalakan saklar.
final assistantContextTitlesProvider = Provider<List<String>>((ref) {
  if (!ref.watch(includeNotesContextProvider)) return const [];
  final notes = ref.watch(notesProvider).value;
  if (notes == null) return const [];
  return [for (final note in notes) note.title];
});

/// Seluruh state layar asisten.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
    this.requestsUsed = 0,
  });

  final List<ChatMessage> messages;
  final bool isStreaming;
  final String? error;
  final int requestsUsed;

  bool get hasMessages => messages.isNotEmpty;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? error,
    bool clearError = false,
    int? requestsUsed,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      requestsUsed: requestsUsed ?? this.requestsUsed,
    );
  }
}

/// Pengendali percakapan asisten.
///
/// Tanggung jawabnya: validasi input, memeriksa API key, menyusun prompt,
/// menjalankan streaming, dan menyimpan cache jawaban. Tidak ada pemanggilan
/// jaringan langsung di sini sehingga bisa diuji dengan fake.
class ChatController extends Notifier<ChatState> {
  static const maxCachedAnswers = 20;

  final Map<String, String> _cache = {};
  bool _cancelRequested = false;
  StreamSubscription<String>? _activeSubscription;
  Completer<void>? _activeCompletion;

  @override
  ChatState build() => const ChatState();

  Future<void> send(
    String rawQuestion, {
    List<String> noteTitles = const [],
    bool includeContext = false,
  }) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || state.isStreaming) return;

    final limit = ref.read(chatRequestLimitProvider);
    if (state.requestsUsed >= limit) {
      state = state.copyWith(
        error:
            'Batas $limit permintaan per sesi tercapai. '
            'Jalankan ulang aplikasi untuk memulai sesi baru.',
      );
      return;
    }

    String? apiKey;
    try {
      apiKey = await ref.read(apiKeyStoreProvider).read();
    } catch (_) {
      state = state.copyWith(
        error:
            'API key tidak bisa dibaca dari penyimpanan aman. '
            'Coba simpan ulang di Pengaturan.',
      );
      return;
    }

    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.user, text: question),
        ],
        error:
            'API key Gemini belum diatur. '
            'Buka tab Pengaturan untuk menambahkannya.',
      );
      return;
    }

    final contextTitles = includeContext ? noteTitles : const <String>[];
    final systemPrompt = buildSystemPrompt(noteTitles: contextTitles);

    // Cache hanya untuk pertanyaan tanpa konteks, karena konteks bisa berubah.
    final cacheKey = contextTitles.isEmpty ? question.toLowerCase() : null;
    final cached = cacheKey == null ? null : _cache[cacheKey];

    final withQuestion = [
      ...state.messages,
      ChatMessage(role: ChatRole.user, text: question),
    ];

    if (cached != null) {
      state = state.copyWith(
        messages: [
          ...withQuestion,
          ChatMessage(role: ChatRole.assistant, text: cached),
        ],
        clearError: true,
      );
      return;
    }

    final assistantIndex = withQuestion.length;
    _cancelRequested = false;
    state = state.copyWith(
      messages: [
        ...withQuestion,
        const ChatMessage(
          role: ChatRole.assistant,
          text: '',
          isStreaming: true,
        ),
      ],
      isStreaming: true,
      clearError: true,
      requestsUsed: state.requestsUsed + 1,
    );

    final buffer = StringBuffer();
    final completion = Completer<void>();
    _activeCompletion = completion;

    try {
      final assistant = ref.read(aiAssistantFactoryProvider)(apiKey);
      final subscription = assistant
          .streamAnswer(question: question, systemPrompt: systemPrompt)
          .listen(
            (chunk) {
              if (_cancelRequested) return;
              buffer.write(chunk);
              _replaceAssistantMessage(
                assistantIndex,
                buffer.toString(),
                isStreaming: true,
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!completion.isCompleted) {
                completion.completeError(error, stackTrace);
              }
            },
            onDone: () {
              if (!completion.isCompleted) completion.complete();
            },
            cancelOnError: true,
          );
      _activeSubscription = subscription;

      await completion.future;

      if (_cancelRequested) {
        _replaceAssistantMessage(
          assistantIndex,
          buffer.isEmpty ? 'Dihentikan.' : '${buffer.toString()} (dihentikan)',
          isStreaming: false,
        );
        return;
      }

      final answer = buffer.toString().trim();
      if (answer.isEmpty) {
        throw const AssistantException(
          'AI tidak mengembalikan teks. Coba lagi.',
        );
      }

      _replaceAssistantMessage(assistantIndex, answer, isStreaming: false);
      if (cacheKey != null) {
        if (_cache.length >= maxCachedAnswers) {
          _cache.remove(_cache.keys.first);
        }
        _cache[cacheKey] = answer;
      }
    } on AssistantException catch (error) {
      _finishWithError(assistantIndex, buffer.toString(), error.message);
    } catch (_) {
      _finishWithError(
        assistantIndex,
        buffer.toString(),
        'Terjadi kesalahan saat menghubungi AI.',
      );
    } finally {
      await _activeSubscription?.cancel();
      _activeSubscription = null;
      _activeCompletion = null;
      if (state.isStreaming) {
        state = state.copyWith(isStreaming: false);
      }
    }
  }

  /// Menghentikan streaming yang sedang berjalan tanpa membuang teks parsial.
  void cancel() {
    if (!state.isStreaming) return;
    _cancelRequested = true;
    final completion = _activeCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _activeSubscription?.cancel();
    _activeSubscription = null;
  }

  /// Menghapus percakapan dan cache.
  void clear() {
    if (state.isStreaming) {
      cancel();
    }
    _cache.clear();
    state = const ChatState();
  }

  /// Menutup banner error tanpa menghapus percakapan.
  void dismissError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  void _finishWithError(int index, String partial, String message) {
    if (partial.trim().isEmpty) {
      _removeMessageAt(index);
    } else {
      _replaceAssistantMessage(index, partial, isStreaming: false);
    }
    state = state.copyWith(error: message);
  }

  void _replaceAssistantMessage(
    int index,
    String text, {
    required bool isStreaming,
  }) {
    if (index < 0 || index >= state.messages.length) return;
    final updated = [...state.messages];
    updated[index] = updated[index].copyWith(
      text: text,
      isStreaming: isStreaming,
    );
    state = state.copyWith(messages: updated);
  }

  void _removeMessageAt(int index) {
    if (index < 0 || index >= state.messages.length) return;
    final updated = [...state.messages]..removeAt(index);
    state = state.copyWith(messages: updated);
  }
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);
