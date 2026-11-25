# EcoTrash

[![Flutter CI](https://github.com/keshafaryl14/ecotrash/actions/workflows/flutter.yml/badge.svg)](https://github.com/keshafaryl14/ecotrash/actions/workflows/flutter.yml)

EcoTrash menghubungkan masyarakat dengan pemilahan sampah, bank sampah, layanan
penjemputan, poin, dan edukasi keberlanjutan. Aplikasi menggunakan Flutter,
Material 3, Riverpod, dan GoRouter.

## Fitur

- Onboarding, autentikasi lokal, dan profil dengan ubah nama serta tema terang,
  gelap, atau mengikuti sistem.
- Beranda dengan saldo poin aktual, pintasan fitur, dan tips pemilahan.
- Material You: warna sistem dinamis pada Android yang mendukungnya, fallback
  palet Hijau Bumi, empat palet pilihan, serta mode terang, gelap, dan AMOLED.
- Komponen lingkungan reusable dan animasi ilustrasi buatan Flutter; animasi
  dapat dimatikan dari Profil dan otomatis menghormati pengaturan reduce motion.
- Smart Scan melalui kamera/galeri, hasil klasifikasi mock, panduan penanganan,
  dan riwayat lokal. Model ML belum dipasang.
- Direktori OpenStreetMap dengan lokasi GPS, pencarian, filter, dan sepuluh
  bank sampah demo.
- Pemesanan penjemputan bertahap, status simulasi, riwayat, pembatalan,
  notifikasi lokal, dan perolehan poin saat selesai.
- Rewards dengan histori transaksi, level, katalog e-wallet dan voucher ramah
  lingkungan, serta halaman voucher aktif/terpakai/kedaluwarsa.
- Artikel pemilahan organik, anorganik, dan B3, detail artikel, serta kuis lima
  pertanyaan.

## Status demo dan batasan

Repository dan data mitra masih lokal/dummy. Smart Scan belum memakai model
ML; status penjemputan berjalan otomatis setiap 30 detik; kode e-wallet
merupakan kode demo dan tidak memindahkan saldo sungguhan. Poin disimpan lokal
di perangkat. Data contoh dan akses GPS tidak menggantikan layanan produksi.
Pengujian pada ponsel fisik dan build rilis tetap memerlukan Android SDK,
perangkat, serta keystore milik pemilik aplikasi.

## Arsitektur

Struktur feature-first memisahkan entity/kontrak di `domain`, implementasi lokal
di `data`, dan UI/provider di `presentation`.

```text
lib/
  core/          tema, router, konstanta, layanan bersama, widget
  features/
    auth/ home/ smart_scan/ waste_bank_directory/
    pickup/ rewards/ education/ profile/
test/
```

State dikelola dengan Riverpod, navigasi dengan GoRouter. `shared_preferences` dipakai untuk prototipe lokal. Tarif, bonus, level, batas
penukaran, masa berlaku voucher, dan estimasi CO₂ dipusatkan di
`lib/features/rewards/domain/rewards_config.dart`.

Preferensi tema, seed warna, mode AMOLED, dan pilihan Animasi Bumi disimpan lokal.
Style Guide khusus debug dapat dibuka melalui `/debug/style-guide`; halaman ini
memperlihatkan role warna Material, tipografi, komponen, dan ilustrasi. Animasi
tidak memakai aset Lottie/Rive atau font eksternal, sehingga seluruh ilustrasi
tetap berbasis kode dan mengikuti opsi aksesibilitas perangkat.

## Aturan poin dan Rewards

- Poin per kg: plastik 10, kertas/kardus 6, kaca 8, logam 15, dan elektronik
  kecil 20. Organik dan B3 tidak menghasilkan poin.
- Pickup minimal 10 kg mendapat bonus 10%; pickup pertama mendapat bonus 20
  poin. Kuis dengan semua jawaban benar mendapat 10 poin sekali per hari.
- Level dihitung dari total poin masuk: Pemula (0), Pejuang Hijau (500), dan
  Pahlawan Bumi (2.000). Penukaran dibatasi tiga reward per hari.
- Reward dapat ditukar dengan saldo e-wallet demo atau voucher diskon. Voucher
  berlaku 30 hari; pembatalan voucher aktif mengembalikan poin hanya dalam 24
  jam. Riwayat mencatat poin masuk, keluar, sumber, referensi, dan tanggal.
- Nominal e-wallet dan kode transaksi adalah **simulasi lokal**, bukan transfer
  uang. Notifikasi dan QR juga berjalan di sisi aplikasi.

Saldo pada implementasi `SharedPreferencesPointsService` hanya disimpan di
perangkat, sehingga tidak aman sebagai sumber kebenaran untuk transaksi
produksi. Sebelum peluncuran, pindahkan validasi saldo, batas/stok reward,
idempotensi, refund, dan transfer e-wallet ke backend tepercaya dengan
transaksi atomik. Jangan menyimpan kredensial payment gateway di aplikasi
mobile. `PointsService` serta `EwalletPayoutGateway`/`EwalletPayoutService`
menjadi kontrak pengganti implementasi demo.

## Menjalankan aplikasi

Pasang Flutter stable, Git, Android Studio, dan Android SDK. Dari root proyek:

```shell
flutter doctor
flutter pub get
flutter devices
flutter run
```

### Android

Aktifkan **Developer Options** dan **USB debugging**, sambungkan perangkat
(atau aktifkan Wireless Debugging), lalu pastikan perangkat tampil di
`flutter devices`. Terima dialog otorisasi USB dan jalankan `flutter run`.
Jika lisensi Android belum diterima, jalankan `flutter doctor --android-licenses`.

### iOS (memerlukan Mac)

Pasang Xcode dan CocoaPods, buka `ios/Runner.xcworkspace`, pilih target Runner,
atur **Team** pada **Signing & Capabilities**, dan gunakan Bundle Identifier
unik. Pilih iPhone sebagai perangkat lalu tekan **Run**, atau jalankan
`flutter devices` dan `flutter run` dari terminal Mac.

### VS Code

Pasang ekstensi Flutter (Dart akan ikut tersedia), pilih perangkat, lalu tekan
**F5** untuk debug. Saat `flutter run` aktif, `r` atau menyimpan file melakukan
hot reload; `R` melakukan hot restart.

## Mengganti repository lokal dengan Firebase

1. Tambahkan `firebase_core`, `firebase_auth`, `cloud_firestore`, dan
   `firebase_storage` sesuai kebutuhan. Konfigurasikan Firebase untuk Android
   dan iOS melalui FlutterFire CLI; jangan commit file kredensial privat.
2. Inisialisasi Firebase sebelum `runApp` di `lib/main.dart`.
3. Implementasikan kontrak `AuthRepository` dengan Firebase Auth, lalu ganti
   binding `authRepositoryProvider` di
   `lib/features/auth/presentation/providers/auth_providers.dart`.
4. Implementasikan `PickupOrderRepository` dan `RewardRepository` dengan
   Firestore. Untuk poin, gunakan operasi transaksi Firestore agar debit,
   saldo, dan klaim reward atomik serta tetap idempoten.
5. Ganti `WasteBankRepository` dengan API mitra, `ScanHistoryRepository` dengan
   Firestore/Storage, dan `EwalletPayoutService` dengan backend payment gateway.
   Jangan menaruh secret e-wallet atau service-account key di aplikasi mobile.
6. Tambahkan aturan Firestore/Storage berdasarkan UID, validasi server-side,
   dan migrasikan data lokal secara bertahap.

Kontrak dan implementasi lokal yang menjadi titik integrasi:
`AuthRepository`, `PickupOrderRepository`, `WasteBankRepository`,
`RewardRepository`, `PointsService`, dan `EwalletPayoutService`.

## Testing dan analisis

```shell
flutter analyze
flutter test
flutter build apk --debug
```

Test mencakup validasi auth, navigasi, edukasi/kuis, pengaturan tema, skema
warna, animasi, pemesanan, transaksi poin, level, voucher, dan pembatalan.
Golden tema dapat diperbarui dengan `flutter test --update-goldens
test/core/app_theme_golden_test.dart`. Saran integration test tambahan
di `integration_test/`: registrasi dan login; buka Smart Scan lalu pilih foto;
buat pesanan pickup dan majukan status sampai selesai; pastikan poin bertambah
dan dapat ditukar. Jalankan pada emulator/perangkat dengan
`flutter test integration_test`.

## CI/CD

GitHub Actions menjalankan `flutter pub get`, `flutter analyze`, `flutter test`,
dan build APK debug pada setiap push dan pull request. APK debug diunggah
sebagai artifact `ecotrash-debug-apk` selama tujuh hari. Workflow manual
memiliki opsi membangun AAB rilis bertanda tangan.

## Signing Android

Buat keystore upload lokal dan simpan di lokasi yang aman:

```shell
keytool -genkeypair -v -keystore android/app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Pada PowerShell, tanda backtick menyambung baris; perintah juga dapat dijalankan
dalam satu baris. Buat `android/key.properties` secara lokal (sudah di-ignore):

```properties
storeFile=upload-keystore.jks
storePassword=ISI_PASSWORD_STORE
keyAlias=upload
keyPassword=ISI_PASSWORD_KEY
```

Jangan commit file `.jks`, `.keystore`, atau `key.properties`. Untuk workflow
manual rilis, tambahkan GitHub Actions Secrets:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
dan `ANDROID_KEY_PASSWORD`. `ANDROID_KEYSTORE_BASE64` adalah isi keystore
terenkode Base64; simpan langsung sebagai secret, jangan cetak atau masukkan ke
source control. Job rilis mendekodenya sementara di runner dan mengunggah
artifact `ecotrash-release-aab`.

Build lokal setelah `key.properties` diisi:

```shell
flutter build apk --release
# atau
flutter build appbundle --release
```

Simpan salinan keystore dan password di password manager/backup aman. Kehilangan
upload key dapat menghambat pembaruan aplikasi yang sudah dipublikasikan.

## Git

Gunakan `main` untuk rilis, `develop` untuk integrasi, dan
`feature/nama-fitur` untuk pekerjaan fitur. Format commit mengikuti Conventional
Commits, misalnya `feat: add education quiz` atau `fix: persist theme choice`.
