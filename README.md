# Doran Pay - Aplikasi E-Wallet & Payment Gateway

Proyek ini adalah bagian dari tugas **Ujian Akhir Semester (UAS) Genap 2025/2026** untuk mata kuliah **Aplikasi Mobile Lanjutan**.

### 👤 Identitas Mahasiswa
* **Nama**: [Tulis Nama Anda Di Sini]
* **NIM**: [Tulis NIM Anda Di Sini]
* **Kelas**: [Tulis Kelas Anda Di Sini]
* **Matakuliah**: Aplikasi Mobile Lanjutan (KB1154)
* **Program Studi**: Teknik Informatika
* **Dosen Pengampu**: IKetut Gunawan, S.KOM, M.T.I
* **Institut**: Institut Teknologi & Bisnis Bina Sarana Global

---

## 1. 📱 Deskripsi Aplikasi
**Doran Pay** adalah aplikasi dompet digital (E-Wallet) dan payment gateway mandiri yang dibangun menggunakan Flutter. Aplikasi ini berfungsi sebagai penyedia layanan pembayaran digital (wallet) yang diintegrasikan langsung secara *App-to-App* dengan aplikasi e-commerce **Doran Gaming Console** melalui mekanisme **Deep Link**.

### Fitur Utama:
* **Manajemen Saldo**: Menampilkan informasi saldo akun pengguna secara real-time.
* **Otentikasi & Registrasi**: Pendaftaran akun baru dengan verifikasi keamanan awal.
* **Integrasi Pembayaran (Deep Link)**: Menerima permintaan checkout belanja dari aplikasi E-Commerce, memproses pembayaran, memotong saldo, dan mengembalikan status transaksi sukses/gagal ke aplikasi E-Commerce.
* **Two-Factor Authentication (2FA)**: Pengamanan transaksi digital menggunakan verifikasi 2 langkah (Email OTP, Google Authenticator TOTP, dan Push Notification).
* **Riwayat Transaksi**: Mencatat semua detail pengeluaran (debit) dan pemasukan saldo (credit).
* **Desain Estetika Premium (Persona 5 Royal)**: Antarmuka bertema gelap (*dark theme*) dengan kombinasi warna hitam pekat, abu-abu gelap, dan merah menyala, dilengkapi dengan aksen visual yang memanjakan mata.

---

## 2. 🏗️ Arsitektur Aplikasi
Aplikasi Doran Pay dibangun dengan menerapkan prinsip **Clean Architecture** untuk memastikan kode mudah dipelihara (*maintainable*), diuji (*testable*), dan dikembangkan lebih lanjut. Kode dipisahkan menjadi 3 layer utama:

```
lib/
├── core/
│   ├── constants/       # Konfigurasi URL API & Endpoint
│   └── theme/           # Konfigurasi tema warna gelap & merah
├── data/
│   ├── datasources/     # Pemanggilan REST API Backend & Secure Storage
│   └── models/          # Entitas serialisasi JSON (User, Account, Transaction)
├── domain/
│   ├── usecases/        # Logika bisnis inti yang berdiri sendiri
│   └── repositories/    # Abstraksi antarmuka data
├── presentation/
│   ├── blocs/           # State Management menggunakan BLoC (Auth, Account, OTP)
│   ├── pages/           # Layar Antarmuka (Splash, Login, 2FA, Home, Checkout, Success)
│   └── widgets/         # Komponen UI Reusable (AppButton, AppField, CodeInput)
└── main.dart            # Entry point aplikasi & Routing (GoRouter)
```

### Penjelasan Layer:
1. **Presentation Layer (BLoC)**: Mengelola state aplikasi secara reaktif. BLoC memisahkan logika bisnis dari UI. Halaman-halaman hanya bertugas menampilkan data yang diterima dari state BLoC dan mengirimkan event (misalnya meminta OTP atau mengonfirmasi pembayaran).
2. **Domain Layer**: Merupakan inti aplikasi yang berisi *Usecases* independen tanpa ketergantungan pada library UI.
3. **Data Layer**: Mengurus komunikasi data mentah. Menggunakan **Dio HTTP Client** untuk terhubung ke backend API serta **Flutter Secure Storage** untuk menyimpan token akses JWT secara terenkripsi di penyimpanan lokal HP.

---

## 3. 🔐 Implementasi Deep Link & Keamanan 2FA
Mekanisme ini dirancang untuk memenuhi ketentuan utama integrasi *App-to-App* yang aman:

### A. Alur Deep Link (Checkout Gateway)
1. Aplikasi E-Commerce mengirimkan request checkout dengan memicu tautan:
   `dpay://checkout?amount=xxx&recipient_email=xxx&trx_id=xxx&callback_url=xxx`
2. Aplikasi **Doran Pay** akan menangkap tautan tersebut, membaca parameter transaksi, dan menampilkan halaman pembayaran merchant secara otomatis.
3. Setelah pengguna memasukkan PIN dan memverifikasi kode 2FA, Doran Pay memotong saldo pengguna melalui API backend.
4. Doran Pay membuka kembali aplikasi E-Commerce menggunakan URL callback yang diterima (misal: `ecommerce://callback?status=success&trx_id=xxx&amount=xxx&recipient_email=xxx`).

### B. Opsi Keamanan Two-Factor Authentication (2FA)
Aplikasi mendukung 3 metode 2FA dinamis yang dapat dipilih oleh pengguna:
1. **Email OTP (SMTP)**: Mengirimkan 6 digit kode unik ke alamat email pengguna melalui server SMTP (diimplementasikan pada form registrasi dan checkout).
2. **Authenticator (TOTP)**: Sinkronisasi kode 6 digit berbasis waktu (Time-based One-Time Password) yang terhubung dengan Google Authenticator atau Authy (diaktifkan melalui scan QR Code di menu akun).
3. **Push Notification OTP**: Verifikasi instan melalui pengiriman push message ke HP pengguna menggunakan layanan Firebase Cloud Messaging (FCM).

---

## 4. 🚀 Cara Menjalankan Proyek
Ikuti langkah-langkah berikut untuk menjalankan aplikasi di lingkungan lokal Anda:

### Langkah 1: Persiapan Backend & Database
Pastikan backend `be-emoney` (layanan Go) telah berjalan dan terhubung dengan database lokal Anda sebelum memulai aplikasi mobile.

### Langkah 2: Instalasi Dependensi Flutter
Buka terminal di folder `fe-emoney` lalu jalankan perintah:
```bash
flutter pub get
```

### Langkah 3: Menjalankan Aplikasi
Hubungkan HP Android (aktifkan USB Debugging) atau jalankan Emulator Android, kemudian ketik:
```bash
flutter run
```

---

## 5. 📦 Daftar Dependensi Utama
* `flutter_bloc` & `bloc` — Library state management terstruktur.
* `firebase_core` & `firebase_auth` — Otentikasi pengguna berbasis Firebase.
* `dio` & `pretty_dio_logger` — HTTP client untuk komunikasi API backend dan pencatatan log.
* `flutter_secure_storage` — Penyimpanan token otentikasi JWT secara aman di HP.
* `qr_flutter` — Membuat QR Code untuk integrasi Google Authenticator.
* `pinput` — Kotak masukan kode OTP 6 digit yang responsif.
* `google_fonts` — Pemuatan font sans-serif modern (Plus Jakarta Sans).

---

## 📸 Screenshot Aplikasi
*(Anda dapat melampirkan screenshot antarmuka aplikasi di bawah ini)*

| Halaman Utama (Doran Pay) | Halaman Pembayaran Merchant | Verifikasi Keamanan (2FA) |
| :---: | :---: | :---: |
| ![Home](screenshots/home.png) | ![Checkout](screenshots/checkout.png) | ![Security](screenshots/2fa.png) |

---

## 🎥 Link Video Presentasi
Silakan akses video demonstrasi alur transaksi lengkap dan penjelasan kode program pada tautan YouTube berikut:
* 🔗 **[Link Video Presentasi UAS Mobile Lanjutan](https://youtube.com/...)**
