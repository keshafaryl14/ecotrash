# EcoTrash

EcoTrash adalah aplikasi mobile untuk membantu masyarakat memilah sampah,
menemukan bank sampah, menjadwalkan penjemputan, serta memperoleh reward dari
setoran daur ulang. Antarmuka tahap awal menggunakan Bahasa Indonesia.

## Fitur

- Beranda dengan pintasan fitur dan ringkasan poin.
- Smart Scan memakai kamera atau galeri, menampilkan panduan pemilahan, dan
  menyimpan riwayat lokal. Klasifikasi saat ini masih berupa mock botol PET;
  kerangka integrasi TFLite tersedia, tetapi model belum dipasang.
- Direktori bank sampah di peta OpenStreetMap, dengan pencarian, filter,
  petunjuk arah, dan sepuluh lokasi demo di sekitar GPS pengguna.
- Formulir bertahap untuk menjadwalkan penjemputan sampah, daftar pesanan aktif
  dan riwayat, detail dengan lini masa status, serta pembatalan sebelum kurir
  berangkat.
- Pengingat lokal sebelum jadwal dan notifikasi perubahan status. Status demo
  bergerak otomatis setiap 30 detik; poin ditambahkan ke ledger lokal setelah
  pesanan selesai.
- Rewards dengan saldo dan riwayat poin lokal, level pengguna, katalog voucher,
  voucher e-wallet demo, dan daftar voucher aktif/terpakai/kedaluwarsa.
- Edukasi pemilahan, onboarding, autentikasi, dan profil.

Navigasi utama memiliki lima tab: Beranda, Scan, Peta, Penjemputan, dan Rewards.
Profil dapat dibuka dari Beranda.
Onboarding dan autentikasi lokal berfungsi. Smart Scan meminta izin kamera;
izin galeri dikelola oleh pemilih foto sistem, sedangkan direktori bank sampah
meminta izin lokasi saat dibuka. Layanan penjemputan menyimpan pesanan dan poin
secara lokal untuk demo. Tarif poin per kilogram diatur di
`lib/core/constants/points_configuration.dart`. Kode e-wallet masih berupa
kode demo dan belum mengirim saldo ke penyedia pembayaran.

## Teknologi

- Flutter dan Dart null safety, Material 3.
- Riverpod untuk state management dan GoRouter untuk navigasi.
- `shared_preferences` untuk penyimpanan lokal sederhana dan `intl` untuk
  pemformatan lokal.
- `flutter_local_notifications`, `flutter_timezone`, dan `timezone` untuk
  pengingat serta notifikasi status penjemputan.
- `camera`, `image_picker`, `geolocator`, `flutter_map`, `latlong2`, dan
  `url_launcher` untuk Smart Scan dan direktori bank sampah.
- Struktur feature-first pada `lib/features/`; tema, router, konstanta, utilitas,
  dan widget aplikasi berada di `lib/core/`.

## Menjalankan aplikasi

Pasang Flutter stable, Git, Android Studio, serta Android SDK. Dari root proyek:

```shell
flutter doctor
flutter pub get
flutter devices
flutter run
```

### Android

1. Pasang Android SDK dan command-line tools melalui Android Studio. Jika perlu,
   jalankan `flutter doctor --android-licenses`.
2. Pada ponsel, aktifkan **Developer Options** dan **USB debugging**.
3. Hubungkan ponsel dengan USB (atau Wireless Debugging), lalu pastikan muncul
   di `flutter devices`.
4. Jalankan `flutter run`.

### iOS (memerlukan Mac)

Pasang Xcode dan CocoaPods, buka `ios/Runner.xcworkspace`, pilih target Runner,
dan atur **Team** pada **Signing & Capabilities**. Pastikan Bundle Identifier
unik, pilih iPhone sebagai perangkat, lalu tekan **Run**. Alternatifnya gunakan
`flutter devices` dan `flutter run` dari terminal Mac.

### VS Code

Pasang ekstensi **Flutter** (Dart akan ikut tersedia), pilih perangkat, lalu
tekan **F5** untuk debug. Ketika `flutter run` aktif, tekan `r` atau simpan
berkas untuk hot reload; `R` menjalankan hot restart.

## Struktur proyek

```text
lib/
  core/
    constants/ router/ theme/ utils/ widgets/
  features/
    auth/ education/ home/ pickup/ profile/ rewards/
    smart_scan/ waste_bank_directory/
  main.dart
  app.dart
test/
```

Setiap fitur akan menambah layer `data`, `domain`, dan `presentation` saat
fitur tersebut mulai diimplementasikan. Repository awal direncanakan memakai
data lokal/dummy sebelum integrasi backend.

Direktori bank sampah menggunakan lokasi perangkat dan data mitra dummy di
sekitar lokasi tersebut; penggantian ke API bank sampah dapat dilakukan melalui
`WasteBankRepository`. Autentikasi demo menyimpan sesi aktif, tetapi
akun/kata sandi mock hanya berada di memori proses. Gunakan Firebase Auth untuk
akun persisten dan produksi.

## Analisis dan test

```shell
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions menjalankan `flutter pub get`, analyze, test, dan build APK debug
pada setiap push serta pull request.

## Git

Gunakan `main` untuk rilis, `develop` untuk integrasi, dan
`feature/nama-fitur` untuk pengembangan fitur. Contoh commit awal:

```text
chore: initial project setup
```
