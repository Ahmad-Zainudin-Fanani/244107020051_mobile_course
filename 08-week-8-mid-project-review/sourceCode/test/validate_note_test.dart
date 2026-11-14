import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/validation.dart';

void main() {
  group('validateNoteTitle', () {
    test('menolak judul kosong', () {
      expect(validateNoteTitle(''), emptyNoteTitleMessage);
      expect(validateNoteTitle(null), emptyNoteTitleMessage);
    });

    test('menolak judul yang hanya berisi spasi, tab, dan baris baru', () {
      expect(validateNoteTitle('   '), emptyNoteTitleMessage);
      expect(validateNoteTitle('\t\n '), emptyNoteTitleMessage);
    });

    test('menerima judul yang valid', () {
      expect(validateNoteTitle('Belajar Clean Architecture'), isNull);
    });

    test('menerima judul dengan spasi di awal dan akhir (di-trim)', () {
      expect(validateNoteTitle('  Rencana Mingguan  '), isNull);
    });
  });
}
