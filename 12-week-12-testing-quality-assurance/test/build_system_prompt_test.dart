import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/assistant/domain/usecases/build_system_prompt.dart';

void main() {
  test('system prompt memuat aturan bahasa dan privasi', () {
    final prompt = buildSystemPrompt();

    expect(prompt, contains('Bahasa Indonesia'));
    expect(prompt, contains('maksimal tiga kalimat'));
    expect(prompt, contains('NIK'));
    expect(prompt, isNot(contains('Konteks judul catatan')));
  });

  test('judul catatan masuk sebagai konteks tanpa isi', () {
    final prompt = buildSystemPrompt(
      noteTitles: ['Belanja bulanan', '  Ide aplikasi  ', '   '],
    );

    expect(prompt, contains('- Belanja bulanan'));
    expect(prompt, contains('- Ide aplikasi'));
    final context = prompt.split('hanya judul, tanpa isi):\n').last;
    expect(context, '- Belanja bulanan\n- Ide aplikasi');
  });

  test('judul dibatasi maksimal 20 buah', () {
    final titles = List.generate(25, (index) => 'Catatan $index');

    final prompt = buildSystemPrompt(noteTitles: titles);

    expect(prompt, contains('- Catatan 19'));
    expect(prompt, isNot(contains('- Catatan 20')));
  });

  test('judul panjang dipotong dan diberi elipsis', () {
    final prompt = buildSystemPrompt(noteTitles: ['A' * 100]);

    expect(prompt, contains('${'A' * 59}…'));
    expect(prompt, isNot(contains('A' * 61)));
  });

  test('tanpa judul valid tidak menambah blok konteks', () {
    expect(buildSystemPrompt(noteTitles: ['', '   ']), buildSystemPrompt());
  });
}
