# Ringkasan Cakupan Pengujian

Dokumen ini dihasilkan otomatis agar angkanya bisa diverifikasi ulang, bukan diketik manual.

```bash
python docs/tools/coverage_summary.py \
    --lcov coverage/lcov.info \
    --out docs/coverage-summary.md
```

Sumber: `coverage/lcov.info` dari `flutter test --coverage`.

## 1. Angka utama

| Cakupan | Baris | Persentase |
| :--- | ---: | ---: |
| Seluruh `lib/` | 788/896 | **87.9%** |

Seluruh berkas di `lib/` dapat dijangkau dari `lib/main.dart`; tidak ada kode mati yang dikecualikan dari angka ini.

## 2. Per modul

| Modul | Baris | Persentase |
| :--- | ---: | ---: |
| Fitur catatan | 495/526 | **94.1%** |
| Fitur asisten AI | 273/341 | **80.1%** |
| Inti & validasi | 15/16 | **93.8%** |
| Akses SQLite | 3/10 | **30.0%** |
| Lainnya | 2/3 | 66.7% |

## 3. Berkas dengan baris belum tercakup terbanyak

| Berkas | Cakupan | Baris belum tercakup | Status |
| :--- | ---: | ---: | :--- |
| `lib/features/assistant/presentation/widgets/api_key_card.dart` | 73.2% | 26 | diuji / perlu diuji |
| `lib/features/assistant/presentation/providers/assistant_providers.dart` | 87.1% | 16 | diuji / perlu diuji |
| `lib/features/assistant/data/gemini_assistant.dart` | 80.3% | 13 | diuji / perlu diuji |
| `lib/features/notes/presentation/widgets/notes_list.dart` | 89.4% | 9 | diuji / perlu diuji |
| `lib/features/notes/presentation/pages/note_detail_page.dart` | 88.3% | 9 | diuji / perlu diuji |
| `lib/features/assistant/data/api_key_store.dart` | 0.0% | 9 | diuji / perlu diuji |
| `lib/data/local/db.dart` | 30.0% | 7 | diuji / perlu diuji |
| `lib/features/notes/presentation/pages/notes_page.dart` | 93.3% | 6 | diuji / perlu diuji |
| `lib/features/notes/presentation/widgets/notes_app_bar.dart` | 94.1% | 3 | diuji / perlu diuji |
| `lib/features/notes/presentation/providers/notes_providers.dart` | 92.9% | 2 | diuji / perlu diuji |
| `lib/features/assistant/domain/entities/chat_message.dart` | 71.4% | 2 | diuji / perlu diuji |
| `lib/features/assistant/domain/services/ai_assistant.dart` | 33.3% | 2 | diuji / perlu diuji |
| `lib/features/notes/presentation/widgets/quick_add_bar.dart` | 95.8% | 1 | diuji / perlu diuji |
| `lib/features/notes/data/models/note_model.dart` | 95.2% | 1 | diuji / perlu diuji |
| `lib/data/sync.dart` | 66.7% | 1 | diuji / perlu diuji |
| `lib/core/failures.dart` | 66.7% | 1 | diuji / perlu diuji |

## 5. Catatan interpretasi

- `lib/data/local/db.dart` hanya 30% karena `openNotesDb()` memanggil `getDatabasesPath()` lewat platform channel yang tidak tersedia di `flutter test`. Skemanya tetap diuji lewat `createNotesSchema()` pada database SQLite in-memory.
- Fitur asisten AI diuji dengan `FakeAiAssistant`; panggilan jaringan sungguhan ke Gemini sengaja tidak dijalankan di test otomatis karena butuh API key dan tidak deterministik.
- `lib/main.dart`, `lib/router.dart`, `lib/data/prefs.dart`, dan `lib/pages/settings_page.dart` tidak muncul di `lcov.info` karena tidak diimpor oleh unit/widget test; alur utamanya dijalankan oleh integration test di perangkat. Cakupan integration test belum digabung ke `lcov.info` karena Flutter belum menyatukannya otomatis.
- Angka cakupan bukan target yang dikejar. Bagian yang tidak diuji dipilih berdasarkan risiko, bukan berdasarkan kemudahan menaikkan persentase.
