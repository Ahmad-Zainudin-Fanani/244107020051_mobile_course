# Log AI-Assisted Development — Minggu 10

**Nama:** Ahmad Zainudin Fanani
**NIM:** 244107020051
**Fitur:** asisten chat AI (Gemini) dengan API key aman dan fallback tanpa key
**Basis proyek:** `week5_offline_notes` hasil Minggu 9, disalin apa adanya dari `09-week-9-ai-assisted-development/sourceCode`
**Branch:** `feature/14-ai-assistant-chat` → `develop` → `main`
**Issue:** [#14](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/issues/14)
**Pull Request:** [#15](https://github.com/Ahmad-Zainudin-Fanani/244107020051_mobile_course/pull/15)

> AI dipakai untuk membuat draf dan sebagai reviewer awal. Setiap baris saya baca, setiap API saya cocokkan dengan dokumentasi resmi, dan setiap keputusan di bawah ini bisa saya jelaskan tanpa membuka AI.

---

## 1. Prompt yang dipakai

Prompt disusun dengan formula lima slot, lalu ditempeli potongan kode nyata dari proyek Minggu 9.

```text
Peran: senior Flutter developer yang disiplin pada Clean Architecture.
Konteks: project Flutter feature-first (presentation -> domain <- data),
  Riverpod 3, GoRouter, sqflite, shared_preferences. Fitur notes sudah punya
  Note, NoteRepository, GetNotes, AddNote, dan notesProvider
  (FutureProvider<List<Note>>). Layar memakai MainLayout dengan
  NavigationBar 2 tab: Catatan dan Pengaturan.
Tugas: tambah satu fitur AI berupa chat asisten memakai Gemini API.
  Aturan: API key diisi pengguna lewat Pengaturan dan disimpan di
  flutter_secure_storage; aplikasi harus tetap jalan tanpa key; jawaban
  tampil bertahap (streaming) dan bisa dihentikan; konteks catatan hanya
  judul, opsional, default mati.
Batas: jangan ubah arsitektur Minggu 7-9, jangan panggil HTTP dari widget,
  jangan taruh key di kode/repo, jangan kirim isi catatan, maksimal
  4 berkas inti baru di luar test.
Output: struktur folder, potongan kode per layer, daftar error yang harus
  ditangani, dan minimal 5 test case.
```

Konteks yang ditempel ke AI (bukan seluruh repo, dan tanpa token/secret):

```dart
class Note {
  const Note({this.id, required this.title, this.body = '',
      required this.updatedAt, this.dirty = false});
  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;
}

// presentation/providers/notes_providers.dart
final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async { ... });
```

Prompt review tahap kedua, dijalankan setelah fitur hijau:

```text
Review kode fitur chat AI Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod 3, http, SSE.
Fokus: kebenaran, pembatalan stream, privasi data, biaya API, test.
Abaikan style. Beri temuan dengan level blocker/saran + alasan.
```

---

## 2. Output awal AI

Potongan inti output awal, apa adanya sebelum diverifikasi:

```dart
// Draf 1 — mengikuti contoh modul
final url = Uri.parse(
  'https://generativelanguage.googleapis.com/v1beta/models/'
  'gemini-pro:generateContent?key=$apiKey',   // model + endpoint lama
);

// Draf 2 — key di prefs biasa
const prefs = SharedPreferences.getInstance();
await prefs.setString('gemini_api_key', apiKey); // <-- plaintext

// Draf 3 — status key langsung dibaca di widget
final hasKey = ref.watch(apiKeyStatusProvider).valueOrNull; // <-- API fiktif

// Draf 4 — pembatalan hanya menyalakan flag
await for (final chunk in assistant.streamAnswer(...)) {
  if (_cancelRequested) break; // <-- koneksi tetap terbuka sampai stream selesai
}

// Draf 5 — setiap request membawa seluruh riwayat + isi catatan
'contents': [...riwayat, ...notes.map((n) => n.body)],
```

Draf itu terlihat rapi dan sebagian besar bisa dikompilasi. Kesalahannya justru ada di bagian yang ditulis paling percaya diri: nama model, nama API Riverpod, dan arti "berhenti".

---

## 3. Verifikasi dan halusinasi yang terbukti

### 3.1 `gemini-pro` dan `generateContent` sudah tidak dipakai

Contoh di modul memakai `.../models/gemini-pro:generateContent`. Saya tidak menganggapnya benar hanya karena ada di modul. Saya buka halaman model resmi dan menghitung kemunculan nama model tersebut pada HTML yang dikirim server:

```text
$ GET https://ai.google.dev/gemini-api/docs/models
  [gemini-pro]            hits=0
  [gemini-3.5-flash-lite] hits=3
  [2.5 Flash]             hits=3   (salah satunya: "`gemini-2.5-flash` is deprecated")
```

Halaman deprecations mengonfirmasi hal yang sama:

```text
$ GET https://ai.google.dev/gemini-api/docs/deprecations
  `gemini-2.5-flash` is deprecated and is no longer available to select in
  Google AI Studio... Effective December 1, 2026, all API requests to
  `gemini-2.5-flash` will automatically route to `gemini-3.5-flash-lite`.
  `gemini-3.5-flash-lite` — July 21, 2026 — No shutdown date announced
```

Artinya draf pertama bukan hanya memakai model yang sudah hilang, tetapi juga bentuk endpoint yang berbeda dari dokumentasi saat ini. Halaman text generation resmi sekarang menulis:

```text
POST "https://generativelanguage.googleapis.com/v1beta/interactions?alt=sse"
-H "x-goog-api-key: $GEMINI_API_KEY"
{ "model": "...", "store": false, "input": "...",
  "system_instruction": "...", "stream": true }
```

**Keputusan:** tolak `gemini-pro` dan `generateContent`. Pakai Interactions API dengan `gemini-3.5-flash-lite` (stabil, tanpa tanggal shutdown, dan varian termurah). Parameter `store: false`, `system_instruction`, `alt=sse`, dan `x-goog-api-key` saya cocokkan satu per satu dengan halaman resmi sebelum ditulis ke kode.

Bukti di kode: [`gemini_assistant.dart`](../sourceCode/lib/features/assistant/data/gemini_assistant.dart) menyimpan endpoint dan nama model sebagai konstanta, dan test memeriksa keduanya:

```dart
expect(request.url.toString(), contains('/v1beta/interactions'));
expect(body['model'], GeminiAssistant.defaultModel);
expect(body['store'], false);
```

### 3.2 `AsyncValue.valueOrNull` tidak ada di Riverpod 3

Draf 3 lolos dari mata saya, tetapi tidak lolos dari analyzer. Saya jalankan apa adanya:

```text
$ flutter analyze
  error - The getter 'valueOrNull' isn't defined for the type
  'AsyncValue<bool>'. Try importing the library that defines 'valueOrNull',
  correcting the name to the name of an existing getter, or defining a
  getter or field named 'valueOrNull'.
  - lib\features\assistant\presentation\widgets\api_key_card.dart:111:27
  - undefined_getter

3 issues found.
```

Saya tidak menebak penggantinya. Saya buka source package yang benar-benar terpasang:

```text
$ Select-String riverpod-3.4.3/lib/src/core/async_value.dart "get value"
async_value.dart:557: ValueT? get value => _value?.$1;
```

**Keputusan:** ganti `.valueOrNull` menjadi `.value` (nullable) dan biarkan analyzer yang memastikan. Setelah perubahan: `No issues found!`.

### 3.3 Pembatalan yang tidak benar-benar membatalkan

Draf 4 adalah bug yang paling berbahaya karena **tidak** menghasilkan error dan tidak terlihat di unit test biasa. `await for` menunggu stream selesai; `break` hanya keluar dari loop, sementara koneksi HTTP tetap terbuka dan token tetap dihitung. Tombol "stop" akan terasa berfungsi di UI tetapi tetap membayar permintaan penuh.

Perbaikannya: pegang `StreamSubscription`, selesaikan `Completer` saat pengguna menekan stop, lalu `cancel()` langganan agar koneksi ditutup.

```dart
final subscription = assistant.streamAnswer(...).listen(
  (chunk) { ... },
  onDone: () { if (!completion.isCompleted) completion.complete(); },
  cancelOnError: true,
);
await completion.future;
...
void cancel() {
  _cancelRequested = true;
  _activeCompletion?.complete();
  _activeSubscription?.cancel();
}
```

Perilaku ini sekarang dikunci test, bukan hanya diuji manual. Test memakai stream yang dikendalikan test (`ManualAssistant`), mengirim satu potongan, menekan `cancel()`, lalu memeriksa bahwa teks parsial tersimpan dan penanda streaming berhenti:

```text
$ flutter test test/chat_controller_test.dart
00:00 +6: tombol stop menyimpan teks parsial dan menutup stream
00:00 +9: All tests passed!
```

### 3.4 Test yang salah, bukan kode yang salah

Draf test pertama memakai `expectLater(stream, throwsA(...))` untuk stream yang error. Hasilnya:

```text
Expected: throws <Instance of 'AssistantException'>
  Actual: <Instance of '_ControllerStream<String>'>
   Which: was not a Function or Future
```

Stream bukan `Function` atau `Future`, jadi `throwsA` tidak berlaku. **Keputusan:** ubah test menjadi `expectLater(stream.toList(), throwsA(...))` supaya error benar-benar ditunggu. Setelah itu lima test error/edge case hijau. Ini contoh kegagalan yang justru membuktikan nilai test: yang salah adalah cara saya menguji, bukan perilaku aplikasi.

### 3.5 Cek batas layer

Domain asisten tidak boleh menyentuh Flutter, `http`, atau secure storage:

```text
$ Get-ChildItem lib/features/assistant/domain -Recurse -Filter *.dart |
    Select-String "package:flutter|package:http|flutter_secure_storage"
(tidak ada output)
```

`flutter analyze` bersih, sehingga tidak ada import lintas layer yang lolos.

---

## 4. Saran AI yang ditolak

| Saran AI | Alasan teknis penolakan | Yang dikerjakan |
| :--- | :--- | :--- |
| Simpan API key di `SharedPreferences` supaya "lebih sederhana". | Prefs menyimpan plaintext di XML aplikasi; key bisa dibaca di perangkat root atau lewat backup. Key adalah kredensial berbayar, bukan preferensi tampilan. | `flutter_secure_storage` (Keystore/Keychain) lewat kontrak `ApiKeyStore`, sehingga test memakai fake tanpa platform channel. |
| Kirim isi catatan sebagai konteks agar jawaban "lebih relevan". | Isi catatan bisa memuat data pribadi. Semakin banyak data keluar, semakin besar risiko dan biaya token. Kebutuhan fitur cukup judul untuk menavigasi. | Hanya judul, maksimal 20, dipotong 60 karakter, dan hanya bila pengguna menyalakan saklar (default mati). |
| Retry otomatis tanpa batas saat 429/500. | Justru memperburuk rate limit dan menambah biaya tanpa persetujuan pengguna. Kegagalan berulang harus terlihat oleh pengguna. | Pesan error spesifik per status, tombol coba lagi manual, dan batas 20 permintaan per sesi. |
| Kirim seluruh riwayat percakapan pada setiap permintaan. | Token tumbuh kuadratik terhadap panjang percakapan; di aplikasi berbayar per token ini pemborosan, dan riwayat lama ikut keluar dari perangkat. | Setiap pertanyaan berdiri sendiri; riwayat hanya hidup di memori layar. |
| Tambahkan `temperature`, `top_p`, `top_k` "agar jawaban konsisten". | Dokumentasi resmi menyatakan model Gemini 4 dan 3.6+ **mengabaikan** parameter itu dan hanya mengembalikan header peringatan. Menulisnya memberi ilusi kontrol. | Hanya `generation_config.max_output_tokens = 512`. |
| Pakai `gemini-pro` / `gemini-2.5-flash` seperti contoh modul. | Keduanya sudah tidak tersedia/deprecated; `2.5-flash` dialihkan otomatis ke `3.5-flash-lite` per 1 Desember 2026. Memakai nama lama berarti aplikasi berhenti bekerja tanpa perubahan kode kita. | `gemini-3.5-flash-lite` sebagai konstanta di data layer. |
| Cache semua jawaban, termasuk yang memakai konteks judul. | Konteks judul bisa berubah setelah catatan diedit; cache akan menyajikan jawaban yang tidak lagi sesuai data. | Cache hanya untuk pertanyaan tanpa konteks, maksimal 20 entri, dihapus saat percakapan dibersihkan. |
| Tampilkan jawaban contoh (demo) saat key belum ada. | Jawaban palsu membuat pengguna mengira AI sudah aktif dan menutupi masalah konfigurasi. Modul menekankan fallback yang jelas, bukan simulasi. | Empty state + banner "API key belum diatur" dengan tombol langsung ke Pengaturan. |

---

## 5. Keputusan per berkas

| Berkas | Keputusan | Catatan |
| :--- | :--- | :--- |
| `lib/features/assistant/domain/entities/chat_message.dart` | **Terima** | Model pesan sederhana, tanpa timestamp karena percakapan tidak disimpan. |
| `lib/features/assistant/domain/usecases/build_system_prompt.dart` | **Terima + perketat** | Draf AI mengirim semua judul; ditambah batas 20 judul, potong 60 karakter, dan pembuangan judul kosong. |
| `lib/features/assistant/domain/services/ai_assistant.dart` | **Tulis manual** | Kontrak + `AssistantException` dengan `canRetry` supaya UI tidak menebak jenis kegagalan. |
| `lib/features/assistant/data/gemini_assistant.dart` | **Tolak draf, tulis manual** | Endpoint dan model diganti ke Interactions API + `gemini-3.5-flash-lite`; parser SSE dibuat tahan event rusak. |
| `lib/features/assistant/data/api_key_store.dart` | **Tolak draf prefs, tulis manual** | `flutter_secure_storage` di balik kontrak, key `gemini_api_key`. |
| `lib/features/assistant/presentation/providers/assistant_providers.dart` | **Terima + refactor** | Draf memakai `await for`; diganti `StreamSubscription` + `Completer` agar stop benar-benar menutup stream. Ditambah cache, batas sesi, dan `store: false`. |
| `lib/features/assistant/presentation/pages/assistant_page.dart` | **Terima + rapikan** | Error banner, saklar konteks, tombol stop, dan tautan ke Pengaturan. |
| `lib/features/assistant/presentation/widgets/chat_bubble.dart` | **Terima** | `SelectableText` + indikator streaming kecil. |
| `lib/features/assistant/presentation/widgets/assistant_empty_view.dart` | **Terima + ubah teks** | Teks AI terlalu panjang; dipersingkat dan menyebut data apa yang dikirim. |
| `lib/features/assistant/presentation/widgets/api_key_card.dart` | **Terima + perbaiki** | `.valueOrNull` → `.value`, validasi panjang key, konfirmasi sebelum hapus. |
| `lib/router.dart` | **Terima** | Tab ketiga "Asisten" di `NavigationBar`. |
| `lib/pages/settings_page.dart` | **Terima** | Section baru `ASISTEN AI (GEMINI)` berisi `ApiKeyCard`. |
| `test/gemini_stream_test.dart` | **Tulis manual** | 6 kasus: request benar, event rusak, 401, 429, error di tengah stream, stream tanpa teks. |
| `test/chat_controller_test.dart` | **Tulis manual** | 8 kasus: tanpa key, penggabungan chunk, konteks opt-in, cache, batas sesi, cancel, error, clear. |
| `test/build_system_prompt_test.dart` | **Tulis manual** | 5 kasus batas judul dan privasi. |
| Dependency baru (`google_generative_ai`, `dio`, dll.) | **Tolak** | Satu endpoint HTTP + SSE cukup dengan `http`; SDK pihak ketiga menambah permukaan dependensi tanpa manfaat. |

---

## 6. Uji manual di perangkat

Perangkat: `2209116AG (mobile) • 5751c2fd0013 • android-arm64 • Android 13 (API 33)`.

| Skenario | Langkah | Hasil yang diharapkan | Status |
| :--- | :--- | :--- | :---: |
| Buka tab Asisten | tab **Asisten** | Empty state + 3 contoh pertanyaan | Lolos |
| Tanpa API key | kirim "Apa yang bisa kamu lakukan?" | Pertanyaan tampil, banner "API key Gemini belum diatur", tombol **Pengaturan** | Lolos |
| Simpan key tidak valid | Pengaturan → tempel key pendek → Simpan | Ditolak dengan pesan "terlalu pendek", tidak tersimpan | Lolos |
| Hapus key | Pengaturan → Hapus key → konfirmasi | Status kembali "Belum diatur" | Lolos |
| Konteks mati (default) | kirim pertanyaan | System prompt tanpa blok judul | Lolos |
| Konteks nyala | aktifkan saklar, kirim pertanyaan | System prompt memuat judul catatan | Lolos |
| Hentikan jawaban | kirim pertanyaan, tekan tombol stop | Teks parsial dipertahankan, diberi akhiran "(dihentikan)" | Lolos |
| Hapus percakapan | ikon tempat sampah | Daftar pesan dan banner error kosong | Lolos |

Balasan AI sungguhan tidak bisa diambil karena belum ada API key saat pengerjaan. Jalur yang terbukti di perangkat adalah seluruh alur UI dan fallback; jalur jaringan dibuktikan lewat 6 test parser SSE dengan respons tiruan, dan akan diverifikasi ulang oleh pengguna setelah key diisi.

Bukti visual: [`../Screenshots/assistant_empty.png`](../Screenshots/assistant_empty.png), [`../Screenshots/assistant_no_key.png`](../Screenshots/assistant_no_key.png), [`../Screenshots/settings_api_key.png`](../Screenshots/settings_api_key.png).

---

## 7. Quality gate mesin

Dijalankan di `10-week-10-ai-feature-integration/sourceCode`:

```text
$ flutter analyze
No issues found! (ran in 4.1s)

$ dart format --output=none --set-exit-if-changed .
Formatted 50 files (0 changed)

$ flutter test
00:02 +39: All tests passed!
```

`flutter test` mencakup 17 test lama Minggu 5-9 dan 22 test baru untuk fitur asisten.

---

## 8. Refleksi

**Halusinasi yang paling menonjol** bukan di kode aplikasi, melainkan di contoh yang dipercaya banyak orang: `gemini-pro:generateContent`. Nama model itu tidak lagi muncul di halaman model resmi, dan endpoint yang dipakai dokumentasi sekarang adalah `/v1beta/interactions`. Yang membuat saya menangkapnya adalah kebiasaan menghitung kemunculan string di halaman resmi, bukan membaca sekilas lalu percaya. Halusinasi kedua yang lebih halus adalah `.valueOrNull`: API yang dulu ada di Riverpod 2, lalu hilang di Riverpod 3. Analyzer yang membuktikannya dalam hitungan detik.

**Kesalahan AI yang paling mahal adalah yang tidak error.** `await for` + flag `_cancelRequested` lolos compile, lolos test yang hanya memeriksa teks akhir, dan tetap membayar permintaan penuh meskipun pengguna menekan stop. Saya baru menyadarinya saat menulis ulang mekanisme pembatalan. Pelajarannya: untuk fitur berbiaya, "berhenti" harus berarti koneksi ditutup, bukan sekadar loop dihentikan.

**Prompt yang paling membantu** adalah yang menyebut batas privasi secara eksplisit: "hanya judul, opsional, default mati". Tanpa itu, draf AI langsung mengirim isi catatan karena secara fungsional lebih "berguna". Prompt review tahap kedua juga berhasil menemukan satu blocker nyata (pembatalan stream) yang tidak terlihat dari test kebahagiaan.

**Keputusan tersulit** adalah menolak fallback demo. Demo lokal akan membuat screenshot terlihat lebih meyakinkan tanpa API key, tetapi itu berarti menampilkan jawaban palsu sebagai jawaban AI. Saya memilih empty state + banner yang jujur, dan menutupi jalur jaringan dengan test parser SSE yang deterministik.

**Yang akan saya ubah lain kali:** menulis test pembatalan dan test error sebelum implementasi, bukan sesudah. Dua bug desain di atas (cancel dan `.valueOrNull`) akan langsung terlihat di menit pertama bila test ditulis lebih dulu.
