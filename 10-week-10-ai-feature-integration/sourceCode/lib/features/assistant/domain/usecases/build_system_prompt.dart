/// Batas perilaku asisten Gemini.
///
/// Ditulis di domain supaya aturan prompt bisa diuji tanpa jaringan dan tanpa
/// membangun widget.
const assistantSystemPrompt = '''
Kamu asisten catatan pribadi di aplikasi "Catatan Saya".
Aturan wajib:
- Jawab dalam Bahasa Indonesia dengan maksimal tiga kalimat.
- Gunakan hanya konteks judul catatan yang diberikan.
- Jika konteks tidak cukup, katakan bahwa kamu belum tahu dan minta pengguna membuka catatan terkait.
- Jangan mengarang isi catatan yang tidak ada.
- Jangan meminta atau menyebut NIK, nomor telepon, alamat, atau data pribadi lain.
''';

/// Menyusun system prompt beserta konteks judul catatan.
///
/// Hanya judul yang dikirim, bukan isi catatan. Jumlah dan panjang judul
/// dibatasi supaya token tetap kecil dan data yang keluar dari perangkat
/// seminimal mungkin.
String buildSystemPrompt({
  List<String> noteTitles = const [],
  int maxTitles = 20,
  int maxTitleLength = 60,
}) {
  final titles = noteTitles
      .map((title) => title.trim())
      .where((title) => title.isNotEmpty)
      .take(maxTitles)
      .map((title) => _truncate(title, maxTitleLength))
      .toList();

  if (titles.isEmpty) return assistantSystemPrompt.trim();

  final context = titles.map((title) => '- $title').join('\n');
  return '${assistantSystemPrompt.trim()}\n\n'
      'Konteks judul catatan pengguna (hanya judul, tanpa isi):\n'
      '$context';
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 1).trimRight()}…';
}
