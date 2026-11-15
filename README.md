## Identitas Mahasiswa

| Keterangan | Informasi |
|---|---|
| Nama | Ahmad Zainudin Fanani |
| NIM | 244107020051 |
| Mata Kuliah | Pemrograman Mobile |

---

## Daftar Materi dan Aktivitas Perkuliahan

Portfolio ini berisi rangkuman materi serta tugas yang dikerjakan selama proses pembelajaran Pemrograman Mobile dalam 16 minggu perkuliahan.

| Pertemuan | Materi | Keterangan | Dokumentasi |
|:---:|---|:---:|---|
| 1 | Pengenalan Ekosistem Mobile dan Flutter Refresh | Selesai | [Lihat Materi dan Tugas](./01-week-1-mobile-development-ecosystem-flutter-refresh) |
| 2 | Declarative UI dan Responsive Design | Selesai | [Lihat Materi dan Tugas](./02-week-2-declarative-ui-responsive-design) |
| 3 | Navigation dan State Management | Selesai | [Lihat Materi dan Tugas](./03-week-3-navigation-state-management) |
| 4 | API dan Asynchronous Programming | Selesai | [Lihat Materi dan Tugas](./04-week-4-networking-rest-api) |
| 5 | Local Storage dan Offline-First (SQLite & Shared Preferences) | Selesai | [Lihat Materi dan Tugas](./05-week-5-local-storage-offline-first) |
| 6 | Authentication, Security & FCM | Selesai | [Lihat Materi dan Tugas](./06-week-6-authentication-security-fcm) |
| 7 | Ujian Tengah Semester / UTS Project | Selesai | [Lihat Materi dan Tugas](./07-week-7-clean-architecture) |
| 8 | Mid Project Review & Code Review | Selesai | [Lihat Materi dan Tugas](./08-week-8-mid-project-review) |
| 9 | AI-Assisted Development (Search + Empty State) | Selesai | [Lihat Materi dan Tugas](./09-week-9-ai-assisted-development) |
| 10 | AI Feature Integration (Chat Asisten Gemini + Secure API Key) | Selesai | [Lihat Materi dan Tugas](./10-week-10-ai-feature-integration) |
| 11 | Optimasi Performa (Profiling, Rebuild, dan Query) | Selesai | [Lihat Materi dan Tugas](./11-week-11-performance-optimization) |
| 12 | Pengujian dan Jaminan Kualitas (Unit, Widget, Integration Test) | Selesai | [Lihat Materi dan Tugas](./12-week-12-testing-quality-assurance) |
| 13-16 | Materi dan proyek lanjutan | Belum dikerjakan | - |

## Struktur Setiap Folder Minggu

Semua folder minggu memakai pola yang sama, supaya mudah dicari:

| Isi | Lokasi |
| :--- | :--- |
| Laporan dan dokumentasi | `README.md` serta `docs/` di akar folder minggu |
| Tangkapan layar | `Screenshots/` |
| Proyek Flutter | `sourceCode/` — di dalamnya ada `lib/`, `test/`, `pubspec.yaml`, dan platform (`android/`, `ios/`, dan seterusnya) |

Modul menuliskan struktur `lib/`, `test/`, `docs/`, `README.md`, dan `screenshots/`
langsung di folder minggu. Di repo ini proyek diletakkan di dalam `sourceCode/`
agar laporan dan kode tidak bercampur dalam satu direktori; isi `sourceCode/`
tetap `lib/` dan `test/` seperti yang diminta modul, dan perintah Flutter
dijalankan dari dalam `sourceCode/`.