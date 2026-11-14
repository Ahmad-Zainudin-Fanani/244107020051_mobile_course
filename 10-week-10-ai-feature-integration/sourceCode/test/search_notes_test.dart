import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/search_notes.dart';

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja bulanan', updatedAt: DateTime(2026, 11, 1)),
    Note(id: 2, title: 'belanja harian', updatedAt: DateTime(2026, 11, 2)),
    Note(id: 3, title: 'Rencana rapat', updatedAt: DateTime(2026, 11, 3)),
  ];

  group('searchNotesByTitle', () {
    test('mengabaikan huruf besar/kecil', () {
      final hasil = searchNotesByTitle(notes, 'BELANJA');

      expect(hasil, hasLength(2));
      expect(hasil.map((note) => note.id), containsAll([1, 2]));
    });

    test('mengabaikan spasi di awal dan akhir kata kunci', () {
      final hasil = searchNotesByTitle(notes, '  rencana  ');

      expect(hasil, hasLength(1));
      expect(hasil.single.title, 'Rencana rapat');
    });

    test('kata kunci kosong mengembalikan semua catatan', () {
      expect(searchNotesByTitle(notes, ''), hasLength(notes.length));
      expect(searchNotesByTitle(notes, '   '), hasLength(notes.length));
    });

    test('kata kunci tanpa hasil mengembalikan list kosong', () {
      expect(searchNotesByTitle(notes, 'zzz-tidak-ada'), isEmpty);
    });

    test('mencocokkan sebagian judul, bukan hanya awalan', () {
      final hasil = searchNotesByTitle(notes, 'rapat');

      expect(hasil, hasLength(1));
      expect(hasil.single.id, 3);
    });
  });
}
