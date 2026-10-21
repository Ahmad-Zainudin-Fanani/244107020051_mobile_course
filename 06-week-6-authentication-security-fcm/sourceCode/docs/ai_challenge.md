# AI Challenge Documentation: Campus Notification App

Dokumen ini mendokumentasikan prompt tantangan AI, analisis draf awal kode AI, identifikasi kelemahan/kesalahan, serta perbaikan teknis manual yang dilakukan pada proyek **Campus Notification App (Week 6: Authentication, Security, & FCM)**.

---

## 1. Prompt AI Challenge

Prompt yang diberikan:

> "Aplikasi Flutter Campus Notification App. Stack: firebase_messaging, flutter_local_notifications, flutter_secure_storage, go_router, Riverpod.  
> Buatikan PushService dengan:  
> - requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)  
> - onMessage (tampilkan local notification manual)  
> - onMessageOpenedApp + getInitialMessage (navigasi ke data.route)  
> - subscribe/unsubscribe topic pengumuman-kampus  
> - background handler top-level dengan @pragma('vm:entry-point')  
> Tandai bagian yang BERBEDA untuk Android 13+ vs iOS, dan bagian yang tidak boleh mengakses BuildContext."

---

## 2. Draf Awal yang Dihasilkan AI & Analisis Kritis

Pada draf awal yang biasa dihasilkan oleh AI, ditemukan beberapa potensi kesalahan kritis yang harus ditolak atau diperbaiki secara manual:

### Temuan 1: Background Handler Diletakkan Sebagai Method Kelas
- **Draf Awal AI:** AI sering kali menaruh handler di dalam method class, misalnya `class PushService { Future<void> _handleBackground(RemoteMessage msg) async { ... } }`.
- **Bahaya Teknis:** FCM Background Handler berjalan pada isolate terpisah (bukan isolate UI utama). Jika berupa instance method, Flutter engine tidak dapat menginisialisasi atau memanggilnya saat aplikasi dalam keadaan background/terminated, menyebabkan runtime crash atau notifikasi background tidak terpanggil.
- **Perbaikan Manual:** Mengekstrak handler menjadi fungsi top-level global murni dengan anotasi `@pragma('vm:entry-point')`:
  ```dart
  @pragma('vm:entry-point')
  Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Top-level function, no BuildContext or Riverpod access
  }
  ```

### Temuan 2: `onTokenRefresh` Hanya Dicetak ke Console (`print/debugPrint`)
- **Draf Awal AI:** Sering kali AI hanya menulis:
  ```dart
  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    print("New token: $token");
  });
  ```
- **Bahaya Teknis:** Jika token mengalami rotasi (misalnya saat restore data, update OS, atau token rotasi keamanan berkala) dan tidak dikirimkan ke server backend (`POST /devices`), server akan terus mengirimkan push notification ke token lama yang sudah basi (invalid registration token). Mahasiswa tidak akan menerima notifikasi perkuliahan.
- **Perbaikan Manual:** Menghubungkan listener `onTokenRefresh` ke sinkronisasi aktual ke backend dan meng-update notifier state aplikasi:
  ```dart
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await _tokenUpdateCallback?.call(newToken);
    // Sinkronisasi aktual ke POST /devices
  });
  ```

### Temuan 3: Kebocoran Data Token (Logging Token Penuh)
- **Draf Awal AI:** AI mencetak token autentikasi dan FCM token secara penuh ke dalam debug log.
- **Bahaya Teknis:** Melanggar prinsip keamanan OWASP Mobile Top 10. Log perangkat dapat dibaca oleh tool debugging atau aplikasi lain dengan permission membaca log, sehingga token berisiko disalahgunakan.
- **Perbaikan Manual:** Membuat fungsi `maskToken(String? token)` yang memotong token (hanya menampilkan 12 karakter pertama diikuti `...`) baik pada log maupun tampilan antarmuka (UI).

### Temuan 4: Ketergantungan Langsung Payload ke Rute Tanpa Normalisasi
- **Draf Awal AI:** Menavigasikan langsung `context.go(message.data['route'])` tanpa validasi.
- **Bahaya Teknis:** Jika backend mengirimkan format tanpa awalan garis miring (misal `"route": "pengumuman/3"`), GoRouter akan melempar exception crash navigasi.
- **Perbaikan Manual:** Mengekstrak parsing ke dalam pure function `routeFromMessage(Map<String, dynamic> data)` di `lib/routes.dart` yang menangani route kosong, route tanpa leading slash, dan dapat diuji melalui unit test tanpa ketergantungan Firebase SDK.

### Temuan 5: Local Notifications API Breaking Change (v22+)
- **Draf Awal AI:** Menggunakan positional arguments lama pada `_localNotifications.initialize(...)` dan `_localNotifications.show(...)`.
- **Bahaya Teknis:** Menyebabkan kegagalan kompilasi pada versi package terbaru (`flutter_local_notifications: ^22.3.2`).
- **Perbaikan Manual:** Menyesuaikan sintaks pemanggilan menggunakan parameter bernama (`settings: ...`, `id: ...`, `title: ...`, `body: ...`, `notificationDetails: ...`).

---

## 3. Jawaban Checklist AI Verification

1. **Apakah background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')`?**  
   **Ya.** Fungsi `firebaseMessagingBackgroundHandler` berada di luar deklarasi kelas (top-level) dan memiliki anotasi `@pragma('vm:entry-point')`, serta tidak mengakses `BuildContext` atau Riverpod.

2. **Apakah `onTokenRefresh` benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?**  
   **Ya.** `onTokenRefresh` dipasang dengan callback yang memicu sinkronisasi ke backend (disimulasikan payload `POST /devices`) serta memperbarui state `fcmTokenProvider`.

3. **Apakah foreground memakai local notification manual?**  
   **Ya.** Karena sistem Android/iOS tidak secara otomatis memunculkan banner notifikasi saat aplikasi berada di latar depan (foreground), kami menginisialisasi `flutter_local_notifications` dan menampilkan banner secara eksplisit saat event `FirebaseMessaging.onMessage` diterima.

4. **Apakah klik dari ketiga state (foreground, background, terminated) masuk ke rute yang benar?**  
   **Ya.** Seluruh event klik meneruskan payload `data.route` yang dinormalisasi menuju `/pengumuman/3` melalui GoRouter.

5. **Apakah token/secret tidak di-hardcode dan tidak di-log penuh?**  
   **Ya.** Tidak ada token/secret yang di-hardcode. Penyimpanan token access dan refresh menggunakan Keystore/Keychain terenkripsi melalui `flutter_secure_storage`. Seluruh penulisan dan visualisasi token dipotong maksimal 12 karakter pertama (`...`).

6. **Keputusan final dan alasan teknis:**  
   Arsitektur final memisahkan concern secara modular: `TokenStore` untuk enkripsi data lokal, `AuthRepository` untuk simulasi sesi, `buildApiClient` dengan retry interceptor otomatis untuk menangani status HTTP 401, `PushService` untuk lifecycle FCM dan notifikasi lokal, serta `routeFromMessage` sebagai pure function yang diverifikasi melalui unit test.
