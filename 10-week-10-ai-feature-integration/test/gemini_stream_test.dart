import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:week5_offline_notes/features/assistant/data/gemini_assistant.dart';
import 'package:week5_offline_notes/features/assistant/domain/services/ai_assistant.dart';

String _event(String name, String json) => 'event: $name\ndata: $json\n\n';

String _successStream() {
  final buffer = StringBuffer()
    ..write(
      _event(
        'interaction.created',
        '{"event_type":"interaction.created","interaction":{"id":"v1_test"}}',
      ),
    )
    ..write(
      _event(
        'step.start',
        '{"event_type":"step.start","index":1,"step":{"type":"model_output"}}',
      ),
    )
    ..write(
      _event(
        'step.delta',
        '{"event_type":"step.delta","index":1,'
            '"delta":{"type":"text","text":"Halo"}}',
      ),
    )
    ..write(
      _event(
        'step.delta',
        '{"event_type":"step.delta","index":1,'
            '"delta":{"type":"text","text":" dunia"}}',
      ),
    )
    ..write(_event('step.stop', '{"event_type":"step.stop","index":1}'))
    ..write('data: [DONE]\n\n');
  return buffer.toString();
}

http.Client _clientReturning(
  String body, {
  int status = 200,
  void Function(http.BaseRequest request)? onRequest,
}) {
  return MockClient.streaming((request, bodyStream) async {
    onRequest?.call(request);
    return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
  });
}

void main() {
  test(
    'menggabungkan potongan teks dan mengirim permintaan yang benar',
    () async {
      http.BaseRequest? captured;
      final client = _clientReturning(
        _successStream(),
        onRequest: (request) => captured = request,
      );
      final assistant = GeminiAssistant(apiKey: 'AIza-test', client: client);

      final chunks = await assistant
          .streamAnswer(question: 'Halo?', systemPrompt: 'Kamu asisten.')
          .toList();

      expect(chunks, ['Halo', ' dunia']);

      final request = captured! as http.Request;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.toString(), contains('/v1beta/interactions'));
      expect(request.url.queryParameters['alt'], 'sse');
      expect(request.headers['x-goog-api-key'], 'AIza-test');
      expect(body['model'], GeminiAssistant.defaultModel);
      expect(body['stream'], true);
      expect(body['store'], false);
      expect(body['input'], 'Halo?');
      expect(body['system_instruction'], 'Kamu asisten.');
    },
  );

  test('mengabaikan event yang bukan teks dan data rusak', () async {
    final buffer = StringBuffer()
      ..write('data: bukan-json\n\n')
      ..write(
        _event(
          'step.delta',
          '{"event_type":"step.delta","index":0,'
              '"delta":{"type":"thought_signature","signature":"abc"}}',
        ),
      )
      ..write(
        _event(
          'step.delta',
          '{"event_type":"step.delta","index":1,'
              '"delta":{"type":"text","text":"Jawaban"}}',
        ),
      );
    final assistant = GeminiAssistant(
      apiKey: 'AIza-test',
      client: _clientReturning(buffer.toString()),
    );

    final chunks = await assistant
        .streamAnswer(question: 'Halo?', systemPrompt: 'Sistem')
        .toList();

    expect(chunks, ['Jawaban']);
  });

  test('menerjemahkan 401 menjadi pesan API key ditolak', () async {
    final assistant = GeminiAssistant(
      apiKey: 'salah',
      client: _clientReturning(
        '{"error":{"message":"API key not valid"}}',
        status: 401,
      ),
    );

    await expectLater(
      assistant
          .streamAnswer(question: 'Halo?', systemPrompt: 'Sistem')
          .toList(),
      throwsA(
        isA<AssistantException>()
            .having((e) => e.message, 'message', contains('API key ditolak'))
            .having((e) => e.canRetry, 'canRetry', isFalse),
      ),
    );
  });

  test('menerjemahkan 429 menjadi pesan kuota habis', () async {
    final assistant = GeminiAssistant(
      apiKey: 'AIza-test',
      client: _clientReturning('{"error":{"message":"Quota"}}', status: 429),
    );

    await expectLater(
      assistant
          .streamAnswer(question: 'Halo?', systemPrompt: 'Sistem')
          .toList(),
      throwsA(
        isA<AssistantException>()
            .having((e) => e.message, 'message', contains('Kuota'))
            .having((e) => e.canRetry, 'canRetry', isTrue),
      ),
    );
  });

  test('event error di tengah stream jadi AssistantException', () async {
    final assistant = GeminiAssistant(
      apiKey: 'AIza-test',
      client: _clientReturning(
        _event(
          'error',
          '{"event_type":"error","error":{"message":"Deadline expired"}}',
        ),
      ),
    );

    await expectLater(
      assistant
          .streamAnswer(question: 'Halo?', systemPrompt: 'Sistem')
          .toList(),
      throwsA(
        isA<AssistantException>().having(
          (e) => e.message,
          'message',
          contains('Deadline expired'),
        ),
      ),
    );
  });

  test('stream tanpa teks dianggap gagal, bukan jawaban kosong', () async {
    final assistant = GeminiAssistant(
      apiKey: 'AIza-test',
      client: _clientReturning(
        _event(
          'interaction.completed',
          '{"event_type":"interaction.completed",'
              '"interaction":{"status":"completed"}}',
        ),
      ),
    );

    await expectLater(
      assistant
          .streamAnswer(question: 'Halo?', systemPrompt: 'Sistem')
          .toList(),
      throwsA(
        isA<AssistantException>().having(
          (e) => e.message,
          'message',
          contains('tidak mengembalikan teks'),
        ),
      ),
    );
  });
}
