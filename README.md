# Mutasi Berkas Mobile Khanza

Mutasi Berkas Mobile Khanza adalah aplikasi mobile pendukung SIMRS Khanza yang dirancang untuk mempermudah pelacakan dan manajemen mutasi berkas rekam medis di rumah sakit. Aplikasi ini mengintegrasikan pemindaian barcode/QR code dengan sistem backend yang efisien untuk memastikan akurasi lokasi berkas secara real-time.

## ✨ Fitur Utama

- **🔍 Pencarian Berkas**: Mencari lokasi berkas rekam medis berdasarkan nomor RM atau nama pasien.
- **📦 Batch Scanning**: Update lokasi berkas secara massal menggunakan pemindaian barcode/QR.
- **📋 Picking List**: Daftar berkas yang perlu diambil untuk kebutuhan pelayanan.
- **🗺️ Shelf Mapping**: Pemetaan berkas ke rak/sekat tertentu untuk merapikan penyimpanan.
- **🛡️ Sinkronisasi Real-time**: Terhubung langsung dengan database SIMRS Khanza melalui backend yang aman.

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Scanning**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner) & [Google ML Kit](https://developers.google.com/ml-kit)
- **UI**: Material 3 dengan Google Fonts (Inter)

### Backend (Server)
- **Language**: [Rust](https://www.rust-lang.org/)
- **Web Framework**: [Axum](https://github.com/tokio-rs/axum)
- **Database Wrapper**: [SQLx](https://github.com/launchbadge/sqlx) (MySQL)
- **Async Runtime**: [Tokio](https://tokio.rs/)

## 🚀 Memulai

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Rust Toolchain](https://www.rust-lang.org/tools/install)
- Akses ke Database SIMRS Khanza (MySQL/MariaDB)

### Setup Backend
1. Masuk ke direktori backend: `cd backend`
2. Salin file `.env.example` ke `.env` dan sesuaikan konfigurasi database.
3. Jalankan server: `cargo run`

### Setup Frontend
1. Instal dependensi: `flutter pub get`
2. Sesuaikan alamat IP API di `lib/main.dart`.
3. Jalankan aplikasi: `flutter run`

---
*Dibuat dengan ❤️ untuk kemajuan manajemen rekam medis.*
