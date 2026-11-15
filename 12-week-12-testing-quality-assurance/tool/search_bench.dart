// Benchmark kecil untuk mengukur biaya penyaringan judul.
//
// Jalankan dari folder minggu ini:
//   dart run tool/search_bench.dart
//
// Tujuannya bukan mengukur UI, melainkan menunjukkan berapa kali kerja
// penyaringan yang dihemat oleh debounce 250 ms pada kolom pencarian.
//
// Skrip CLI: mencetak hasil ke stdout, jadi `print` memang disengaja.
// ignore_for_file: avoid_print

import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/search_notes.dart';

const _titles = [
  'Rencana rapat mingguan',
  'Belanja bulanan keluarga',
  'Ide aplikasi catatan offline',
  'Review pull request Minggu 8',
  'Belajar Clean Architecture',
  'Daftar buku yang ingin dibaca',
  'Rencana liburan akhir tahun',
  'Catatan rapat koordinasi tim',
  'Anggaran transportasi bulan ini',
  'Checklist presentasi proyek',
];

List<Note> _seed(int count) => List.generate(
  count,
  (i) => Note(
    id: i + 1,
    title: '${_titles[i % _titles.length]} ${i + 1}',
    updatedAt: DateTime(2026, 11, 15),
  ),
);

/// Rata-rata durasi (mikrodetik) dari [runs] eksekusi.
double _avgMicros(void Function() body, {int runs = 200}) {
  // Pemanasan agar JIT tidak masuk ke pengukuran.
  for (var i = 0; i < 20; i++) {
    body();
  }
  final watch = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    body();
  }
  watch.stop();
  return watch.elapsedMicroseconds / runs;
}

void main() {
  final notes = _seed(1500);
  const query = 'rencana rapat';

  final singlePass = _avgMicros(() => searchNotesByTitle(notes, query));
  final thirteenPasses = _avgMicros(() {
    // Meniru 13 ketikan: 'r', 're', ... 'rencana rapat'.
    for (var i = 1; i <= query.length; i++) {
      searchNotesByTitle(notes, query.substring(0, i));
    }
  }, runs: 100);

  final saved = thirteenPasses - singlePass;
  final percent = saved / thirteenPasses * 100;

  print('catatan            : ${notes.length}');
  print('1 pass             : ${singlePass.toStringAsFixed(1)} us');
  print('13 pass (mengetik) : ${thirteenPasses.toStringAsFixed(1)} us');
  print(
    'dihemat debounce   : ${saved.toStringAsFixed(1)} us '
    '(${percent.toStringAsFixed(1)}%)',
  );
}
