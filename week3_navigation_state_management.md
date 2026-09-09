# 1. Selamat datang
Terakhir diperbarui: 31 Agustus 2026

## Tujuan pembelajaran
Setelah menyelesaikan codelab ini, mahasiswa mampu:

menjelaskan konsep navigasi, route, dan perbedaan Navigator 1.0 dengan GoRouter;
menerapkan navigasi multi-page dengan GoRouter, termasuk passing argument dan deep link sederhana;
menjelaskan mengapa state management diperlukan dan cara kerja Riverpod (Provider, ConsumerWidget, Notifier);
menggunakan AsyncValue untuk menangani state loading, error, dan success pada UI;
membangun aplikasi ToDo dengan navigasi dan Riverpod, lalu memverifikasi hasilnya dengan widget test sederhana.
## Persiapan
Laptop/PC, koneksi internet, dan repository portfolio (GitHub/GitLab) dari minggu sebelumnya.
Flutter SDK, VS Code (ekstensi Flutter/Dart), emulator Android atau perangkat fisik.
Pemahaman materi Minggu 1–2: Dart dasar, widget, StatelessWidget/StatefulWidget, layout, dan tema.

# 2. Konsep navigasi dan GoRouter
## Navigation dasar di Flutter
Navigasi adalah mekanisme berpindah antar layar. Di Flutter, setiap layar adalah route yang ditumpuk pada Navigator (stack). Cara lama (Navigator 1.0) menggunakan Navigator.push dan Navigator.pop:

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DetailPage()),
);
Cara ini sederhana tetapi sulit dikelola pada aplikasi besar: route tidak terstruktur, deep link rumit, dan guard (misalnya redirect login) tersebar di banyak tempat.

## GoRouter
GoRouter adalah router deklaratif yang direkomendasikan Flutter. Konsep utamanya:

Konsep	Penjelasan
GoRoute	Definisi path dan widget tujuan, misal /, /detail/:id.
context.go()	Pindah route (mengganti stack, cocok untuk redirect login).
context.push()	Tumpuk route baru di atas stack (cocok untuk detail).
path parameter	Nilai dinamis pada path, diakses lewat state.pathParameters.
extra	Mengirim objek antar route (gunakan hati-hati, tidak tersimpan saat proses restart web).
redirect	Guard navigasi terpusat, misal cek status login.
Praktikum 1 — Aplikasi multi-page dengan GoRouter
Buat project baru:

flutter create week3_navigation
cd week3_navigation
flutter pub add go_router
Susun struktur folder:

lib/
├── main.dart
└── pages/
    ├── home_page.dart
    └── detail_page.dart
# 1. Definisikan router di lib/main.dart:

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/detail_page.dart';
import 'pages/home_page.dart';

void main() => runApp(const MyApp());

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) => DetailPage(
            id: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - Navigation',
      routerConfig: _router,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}
Catatan: Perhatikan penggunaan MaterialApp.router, bukan MaterialApp biasa. Router dikonfigurasi lewat parameter routerConfig.

# 2. Halaman Home (lib/pages/home_page.dart):

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          title: Text('Item ${index + 1}'),
          onTap: () => context.go('/detail/${index + 1}'),
        ),
      ),
    );
  }
}
# 3. Halaman Detail (lib/pages/detail_page.dart):

import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail $id')),
      body: Center(child: Text('Anda membuka item dengan id: $id')),
    );
  }
}
# 4. Jalankan dan amati. Buka item, lalu tekan tombol back sistem. Perhatikan bahwa path berubah mengikuti layar aktif, path yang sama juga dapat diakses langsung tanpa melewati Home. Inilah keunggulan router deklaratif dibanding Navigator 1.0.

# 3. State management dengan Riverpod
## Mengapa perlu state management?
setState cukup untuk state lokal satu widget. Namun ketika state harus dibagi antar banyak halaman (misal daftar ToDo yang ditampilkan di Home dan diubah di halaman lain), memindahkan state ke atas widget tree membuat kode rumit (prop drilling). State management memindahkan state keluar dari widget sehingga:

UI dapat dibangun ulang dari state yang sama secara konsisten (UI deklaratif = f(state));
logika bisa diuji tanpa membangun UI;
state tetap hidup meski widget sudah tidak tampil.
Pada mata kuliah ini kita menggunakan Riverpod berbasis Provider yang bersifat compile-safe, tidak bergantung pada BuildContext, dan mudah diuji.

## Konsep inti Riverpod
Konsep	Penjelasan
ProviderScope	Wadah global yang menyimpan semua provider, membungkus root aplikasi.
Provider	Nilai read-only/immutable (misal konfigurasi, service).
Notifier + NotifierProvider	State yang bisa berubah melalui method; UI memanggil method, bukan mengubah state langsung.
ConsumerWidget	Widget yang bisa membaca provider lewat ref.
ref.watch vs ref.read	watch: build ulang saat state berubah (di dalam build). read: sekali baca (di callback/event).
Praktikum 2 — Aplikasi ToDo dengan Riverpod
flutter create week3_todo
cd week3_todo
flutter pub add flutter_riverpod
# 1. Bungkus aplikasi dengan ProviderScope di lib/main.dart:

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/todo_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Week 3 - ToDo',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const TodoPage(),
      );
}
# 2. Buat state dan provider (lib/providers/todo_provider.dart):

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false});
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(int index) {
    final todos = [...state];
    todos[index] = todos[index].copyWith(done: !todos[index].done);
    state = todos;
  }

  void remove(int index) => state = [...state]..removeAt(index);
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);
Catatan: State tidak pernah diubah langsung (state.add(...) salah!). Selalu buat list baru (immutability) agar Riverpod mendeteksi perubahan dan UI ter-rebuild.

# 3. Tampilkan dengan ConsumerWidget (lib/pages/todo_page.dart):

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo Riverpod')),
      body: todos.isEmpty
          ? const Center(child: Text('Belum ada tugas'))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) => ListTile(
                leading: Checkbox(
                  value: todos[index].done,
                  onChanged: (_) =>
                      ref.read(todoListProvider.notifier).toggle(index),
                ),
                title: Text(
                  todos[index].title,
                  style: TextStyle(
                      decoration: todos[index].done
                          ? TextDecoration.lineThrough
                          : null),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      ref.read(todoListProvider.notifier).remove(index),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoListProvider.notifier)
                    .add(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
# 4. Perhatikan pola penting: ref.watch di dalam build membuat halaman otomatis ter-rebuild saat daftar berubah; ref.read(todoListProvider.notifier) di dalam callback hanya memanggil method tanpa berlangganan.

# 4. AsyncValue: loading, error, success
Masalah state asinkron
Banyak state berasal dari proses asinkron (membaca database, memanggil API). UI harus menampilkan tiga kemungkinan: loading (proses berjalan), error (gagal), dan success (data siap). Mengelola tiga flag boolean secara manual rawan kesalahan (isLoading dan hasError bisa tidak konsisten).

## AsyncValue
Riverpod menyediakan AsyncValue<T> yang memodelkan ketiga kondisi tersebut dalam satu tipe. Gunakan AsyncNotifier untuk state asinkron:

class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<String>>(
        ProductsNotifier.new);
Catatan: AsyncValue.guard otomatis menangkap exception dan mengubahnya menjadi AsyncError, hindari blok try/catch manual yang tersebar.

Di sisi UI, AsyncValue dapat dipola dengan when atau if-case matching:

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              FilledButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ListTile(title: Text(products[index])),
        ),
      ),
    );
  }
}
Praktikum 3 — Uji ketiga state
Salin kode di atas ke project ToDo Anda (atau project terpisah) dan jalankan. Amati tampilan loading selama 2 detik pertama.
Ubah build() sementara untuk melempar error: throw Exception('Gagal terhubung ke server');. Jalankan dan amati UI error beserta tombol Coba lagi.
Tekan tombol Coba lagi, ref.invalidate membuat provider dijalankan ulang. Pulihkan kode, pastikan state success tampil.
Refleksikan: mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?
Pola yang sering keliru (bahan ujian): (1) memanggil ref.watch di dalam callback; (2) mengubah state langsung tanpa membuat objek baru; (3) melupakan UI error sehingga aplikasi layar putih saat API gagal; (4) menggunakan setState untuk state lintas halaman.

# 5. AI Challenge
Peran AI pada codelab ini
Untuk materi navigasi dan state management, AI boleh digunakan sebagai co-developer untuk membantu membuat boilerplate, tetapi Anda tetap wajib membaca, menjelaskan, memverifikasi, memperbaiki, dan menguji hasilnya. Nilai bukan pada banyaknya kode yang dihasilkan AI, melainkan pada kualitas prompt, verifikasi, dan dokumentasi.

AI Prompt Challenge
Minta AI coding assistant (Cursor, Copilot, Claude Code, atau tool setara) dengan prompt berikut:

Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
## AI Verification Checklist
Sebelum kode AI diterima, verifikasi hal berikut dan catat temuan Anda di README:

Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?
Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?
Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?
Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?
Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau Consumer bertingkat yang tidak perlu)? Perbaiki ke pola Notifier/ConsumerWidget.
Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
Tanggung jawab teknis: simpan prompt yang digunakan, output awal AI, perbaikan yang Anda lakukan, dan hasil testing pada folder docs/ tugas minggu ini. Saat demo, Anda harus mampu menjelaskan setiap baris kode hasil AI.

# 6. Refactoring dan testing
## Refactoring Challenge
Lakukan refactoring berikut pada aplikasi ToDo Anda, lalu commit dengan pesan yang jelas:

Pisahkan widget bar ToDo menjadi TodoTile tersendiri agar build lebih pendek dan mudah diuji.
Ekstrak logika filter (misal tampilkan hanya yang belum selesai) menjadi Provider turunan yang membaca todoListProvider.
Integrasikan aplikasi ToDo dengan GoRouter: / untuk daftar dan /stats untuk halaman statistik, tambahkan NavigationBar untuk berpindah.
## Testing
Widget test untuk memastikan UI bereaksi terhadap perubahan state provider:

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('Belum ada tugas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}
Jalankan seluruh verifikasi:

flutter analyze
flutter test
## Checklist verifikasi mandiri
Navigasi GoRouter bekerja: pindah halaman, back, dan akses path detail langsung.
ProviderScope membungkus root aplikasi; state ToDo bertahan saat berpindah halaman.
UI AsyncValue menangani loading, error, dan success, bukan hanya success.
flutter analyze tanpa issue dan semua test lulus.
Hasil AI diverifikasi dan didokumentasikan pada folder docs/.

# 7. Tugas, refleksi, dan referensi
## Mini project / Industry Challenge
Bangun aplikasi ToDo dengan navigasi dan Riverpod sebagai tugas minggu ini:

Minimal 2 halaman dengan GoRouter: daftar tugas, halaman detail/statistik.
State dikelola Riverpod (Notifier), UI menggunakan ConsumerWidget.
Tambahkan fitur simulasi asinkron dengan AsyncValue: state loading, error, dan success tampil dengan benar.
Sertakan minimal 1 unit/widget test yang lulus.
Kerjakan bagian AI Challenge dan dokumentasikan prompt, hasil AI, perbaikan, serta alasan keputusan teknis Anda.
Push ke repository portfolio pada folder 03-week-3-navigation-state-management/ dengan struktur lib/, test/, README.md, dan screenshots/. README menjelaskan tujuan, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.
## Refleksi
Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?
Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?
Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?
Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
