# fe-emoney 💚

Frontend aplikasi **E-Money** dengan desain **Neo-Brutalism** berbasis **Flutter/Dart**.

## 🎨 Desain

- **Tema**: Neo-Brutalism — Krem/Off-white & Hitam dengan aksen Hijau
- **Warna utama**: `#FAF7F0` (krem) · `#2D6A4F` (hijau) · `#1A1A1A` (hitam)
- **Font**: [Syne](https://fonts.google.com/specimen/Syne) (heading) + [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk) (body)
- **Style**: Border tebal 2px, box-shadow kotak, tombol animasi press

## 📱 Platform yang Didukung

- ✅ Android (emulator & device fisik)
- ✅ Windows Desktop
- ✅ Web Browser

## 🗂️ Struktur Project

```
lib/
├── core/
│   ├── constants/app_constants.dart  # Base URL & konstanta
│   ├── network/api_client.dart       # Dio HTTP client + JWT interceptor
│   └── theme/app_theme.dart          # Neo-brutalism theme
├── data/
│   ├── models/models.dart            # UserModel, AccountModel, TransactionModel
│   └── repositories/repositories.dart # API calls (Auth, Account, Payment, OTP)
├── presentation/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── onboarding/onboarding_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── verify_email_screen.dart
│   │   ├── dashboard/dashboard_screen.dart
│   │   ├── transaction/
│   │   │   ├── topup_screen.dart
│   │   │   └── transfer_screen.dart
│   │   └── profile/security_screen.dart
│   └── widgets/brutal_widgets.dart   # Reusable Neo-Brutalism widgets
├── providers/
│   ├── auth_provider.dart            # Firebase Auth state management
│   └── account_provider.dart        # Account & transaction state
├── firebase_options.dart             # Firebase platform config
└── main.dart                         # Entry point & routing
```

## ⚙️ Setup Firebase

1. Buka [Firebase Console](https://console.firebase.google.com/) dan pilih project **e-money-c9bec**
2. Tambahkan app Android/Web ke project (jika belum ada)
3. Download `google-services.json` dan letakkan di `android/app/google-services.json`
4. Update `lib/firebase_options.dart` dengan nilai dari Firebase Console:
   - `appId` → dari google-services.json: `mobilesdk_app_id`
   - `messagingSenderId` → `project_number`

```dart
// lib/firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyCWAzGMTyg1uSspi1qfno71sj4iCfp7qGk',
  appId: '1:SENDER_ID:android:APP_ID',  // ← dari google-services.json
  messagingSenderId: 'SENDER_ID',        // ← project_number
  projectId: 'e-money-c9bec',
  storageBucket: 'e-money-c9bec.firebasestorage.app',
);
```

## 🔧 Setup Google Sign-In (Android)

Di `android/app/src/main/AndroidManifest.xml`, pastikan ada intent filter untuk Google Sign-In, atau tambahkan `SHA-1` fingerprint di Firebase Console.

## 🚀 Menjalankan App

```bash
# Install dependencies
flutter pub get

# Jalankan di Android emulator
flutter run -d emulator-5554

# Jalankan di Windows
flutter run -d windows

# Jalankan di Web (Chrome)
flutter run -d chrome
```

## 🌐 API Backend

Backend berjalan di `http://localhost:8080` (Go + Gin).

Base URL otomatis dipilih berdasarkan platform:
- **Android emulator** → `http://10.0.2.2:8080/v1`
- **Windows / Web** → `http://localhost:8080/v1`

## 📋 Fitur

| Fitur | Status |
|-------|--------|
| Splash Screen + Onboarding | ✅ |
| Login Email/Password | ✅ |
| Register + Verifikasi OTP Email | ✅ |
| Google Sign-In | ✅ |
| Dashboard (Saldo + Quick Actions) | ✅ |
| Riwayat Transaksi | ✅ |
| Top Up Saldo | ✅ |
| Transfer dengan OTP | ✅ |
| Pilih OTP: Email / Firebase / TOTP | ✅ |
| Setup Google Authenticator (TOTP) | ✅ |
| QR Code untuk TOTP Setup | ✅ |
| Profil Pengguna | ✅ |
| Pengaturan Keamanan | ✅ |

## 🔐 Alur Keamanan Transfer

```
Pilih nominal → Pilih metode OTP → Kirim OTP → Masukkan kode → Transfer berhasil
```

Metode OTP yang tersedia:
1. **Email OTP** — kode 6 digit dikirim ke email
2. **Firebase Push** — notifikasi push ke HP
3. **TOTP/Google Authenticator** — kode berdasarkan waktu

## 📦 Dependencies Utama

- `firebase_core` + `firebase_auth` — Authentication
- `google_sign_in` — Google OAuth
- `dio` + `pretty_dio_logger` — HTTP requests
- `provider` — State management
- `flutter_secure_storage` — Token storage
- `pinput` — OTP input field
- `qr_flutter` — QR code untuk TOTP setup
- `google_fonts` — Syne + Space Grotesk fonts
- `intl` — Format tanggal Bahasa Indonesia
