/// Aturan validasi judul catatan yang dipakai bersama oleh layer domain dan
/// presentation.
///
/// Berkas ini sengaja hanya bergantung pada Dart murni (tanpa Flutter) agar
/// aturan bisnis dapat diuji cepat melalui `flutter test` tanpa emulator.
library;

const String emptyNoteTitleMessage = 'Judul catatan tidak boleh kosong.';

/// Mengembalikan pesan kesalahan bila [rawTitle] tidak valid, atau `null` bila
/// judul dapat disimpan. Judul dianggap kosong apabila hanya berisi spasi,
/// tab, atau karakter baris baru.
String? validateNoteTitle(String? rawTitle) {
  final title = (rawTitle ?? '').trim();
  if (title.isEmpty) {
    return emptyNoteTitleMessage;
  }
  return null;
}
