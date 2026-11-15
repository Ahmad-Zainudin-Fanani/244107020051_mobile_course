import 'dart:async';

import 'package:week5_offline_notes/features/assistant/data/api_key_store.dart';
import 'package:week5_offline_notes/features/assistant/domain/services/ai_assistant.dart';

/// Penyimpanan key palsu untuk test tanpa platform channel.
class FakeApiKeyStore implements ApiKeyStore {
  FakeApiKeyStore([this.value]);

  String? value;
  int saveCalls = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String apiKey) async {
    saveCalls++;
    value = apiKey;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}

/// Asisten palsu yang langsung mengeluarkan potongan jawaban.
class FakeAssistant implements AiAssistant {
  FakeAssistant({this.chunks = const [], this.error});

  final List<String> chunks;
  final AssistantException? error;
  int calls = 0;
  String? lastQuestion;
  String? lastSystemPrompt;

  @override
  Stream<String> streamAnswer({
    required String question,
    required String systemPrompt,
  }) async* {
    calls++;
    lastQuestion = question;
    lastSystemPrompt = systemPrompt;
    if (error != null) throw error!;
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

/// Asisten palsu yang stream-nya dikendalikan test (untuk uji cancel).
class ManualAssistant implements AiAssistant {
  final controller = StreamController<String>();
  int calls = 0;

  @override
  Stream<String> streamAnswer({
    required String question,
    required String systemPrompt,
  }) {
    calls++;
    return controller.stream;
  }
}
