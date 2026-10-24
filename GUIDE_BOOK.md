# 📖 Panduan Lengkap Voicebox Studio (Guide Book)

Selamat datang di **Voicebox Studio**, sebuah studio suara AI *local-first* berbasis open-source yang menggabungkan kemampuan **kloning suara (Voice Cloning / TTS)** dan **dikte suara global (Voice-to-Text / STT)** tanpa mengirim data pribadi Anda ke cloud.

Dokumen ini adalah panduan lengkap untuk memahami arsitektur, cara kerja, cara instalasi, pemecahan masalah (*troubleshooting*), serta aspek legalitas dan adopsi proyek ini.

---

## 📑 Daftar Isi
1. [Mengapa Backend & Frontend Terpisah?](#1-mengapa-backend--frontend-terpisah)
2. [Persyaratan Sistem](#2-persyaratan-sistem)
3. [Panduan Menjalankan Aplikasi (1-Click Run)](#3-panduan-menjalankan-aplikasi-1-click-run)
4. [Struktur Folder & Manajemen Penyimpanan (Downloads)](#4-struktur-folder--manajemen-penyimpanan-downloads)
5. [Fitur-Fitur Unggulan](#5-fitur-fitur-unggulan)
6. [Troubleshooting & Solusi Error](#6-troubleshooting--solusi-error)
7. [Panduan Adopsi & Legalitas Lisensi MIT](#7-panduan-adopsi--legalitas-lisensi-mit)
8. [Panduan Integrasi Google Gemini Pro & Unduh Model LLM Lokal](#8-panduan-integrasi-google-gemini-pro--unduh-model-llm-lokal)
9. [Roadmap Pengembangan & Perancangan Monorepo](#9-roadmap-pengembangan--perancangan-monorepo)

---

## 1. Mengapa Backend & Frontend Terpisah?

> **Pertanyaan Umum:** *"Kenapa jalannya beda-beda (web dan backend terpisah)? Apakah keduanya tidak bisa jadi satu paket?"*

### Penjelasan Mode Rilis vs Mode Pengembangan:

1. **Pada Mode Rilis / Produksi (`.exe` Installer)**:
   - Voicebox sebenarnya **SUDAH JADI SATU PAKET UTUH**.
   - Saat Anda menginstal aplikasi rilis resmi Voicebox (`voicebox.exe`), aplikasi desktop (Tauri) secara otomatis meluncurkan backend server Python (`voicebox-server.exe`) di latar belakang sebagai *sidecar process*. Pengguna biasa tidak perlu membuka terminal atau menjalankan server secara manual.

2. **Pada Mode Pengembangan / Kode Sumber (Source Code)**:
   - Kita menjalankan backend Python (FastAPI di port `17493`) dan antarmuka (Vite/React di port `5173`) secara terpisah untuk mempermudah pengembangan:
     - **Hot Reload Frontend**: Perubahan tampilan di React langsung ter-update seketika (*instant HMR*) tanpa harus merestart backend.
     - **Hot Reload Backend**: Penambahan logika atau route API di Python langsung reload otomatis via Uvicorn.
     - **Monitoring Log & Model**: Anda dapat memantau proses download model AI berukuran besar (Whisper/Kokoro/Qwen) di terminal backend.

3. **Solusi Otomatisasi 1-Klik**:
   Untuk kenyamanan Anda tanpa repot membuka dua terminal manual, kami telah menyediakan skrip otomatis:
   - **`run-desktop.bat`**: Otomatis mengecek backend, menyalakannya di latar belakang jika belum aktif, lalu langsung membuka aplikasi desktop Tauri.
   - **`run-web.bat`**: Otomatis menyalakan backend di latar belakang lalu membuka antarmuka web di browser.
   - **`start.bat`**: Menu kontrol terpusat untuk memilih mode apa pun yang Anda inginkan.

---

## 2. Persyaratan Sistem

| Komponen | Spesifikasi Rekomendasi | Catatan |
|---|---|---|
| **Sistem Operasi** | Windows 10 / 11 (64-bit) | Didukung penuh |
| **Python** | **Python 3.12.x** (Wajib 3.12) | Versi 3.13 dan 3.14 belum didukung dependensi audio PyTorch |
| **JavaScript Runtime**| **Bun** (>= 1.0.0) | Terinstal otomatis via `setup.bat` di folder user |
| **GPU (Opsional)** | NVIDIA RTX / GTX (CUDA) | Jika tanpa GPU, inferensi otomatis dialihkan ke CPU |
| **Kapasitas Disk** | Minimal 15 GB kosong | Untuk penyimpanan model suara AI dan cache |

---

## 3. Panduan Menjalankan Aplikasi (1-Click Run)

Tersedia file-file berekstensi `.bat` yang siap dijalankan dengan *double-click*:

### A. Langkah Pertama: Setup Dependensi
Sebelum menjalankan untuk pertama kali, jalankan file berikut satu kali:
* **`setup.bat`** (atau pilih menu `[4]` di `start.bat`)
  * Skrip ini akan otomatis menyiapkan lingkungan Python 3.12, menginstal Bun jika belum ada, mendeteksi kartu grafis (NVIDIA CUDA vs CPU), memasang dependensi TTS/STT, dan menginstal paket JavaScript.

### B. Menjalankan Aplikasi
Pilih salah satu cara berikut sesuai kebutuhan:

1. **Jalankan Menu Utama**:
   * *Double-click* **`start.bat`**
   * Pilih menu `[1]` untuk Desktop atau `[3]` untuk Web.

2. **Jalankan Mode Desktop Langsung**:
   * *Double-click* **`run-desktop.bat`**
   * Backend akan otomatis dijalankan di latar belakang dan jendela desktop Voicebox akan terbuka.

3. **Jalankan Mode Web Browser Langsung**:
   * *Double-click* **`run-web.bat`**
   * Backend akan aktif dan antarmuka web dapat dibuka di browser (`http://localhost:5173`).

---

## 4. Struktur Folder & Manajemen Penyimpanan (Downloads)

Semua file unduhan yang berukuran besar **telah dikonsentrasikan ke dalam satu folder lokal** agar drive sistem komputer Anda tidak penuh di tempat tersembunyi:

```text
voiceclone/
├── backend/               # Kode sumber server Python FastAPI
│   └── venv/             # Virtual Environment Python 3.12 lokal
├── app/                   # Kode sumber antarmuka React 18 + Tailwind
├── tauri/                 # Layer aplikasi desktop native Tauri 2 (Rust)
├── web/                   # Antarmuka web client browser
├── downloads/             # 📁 FOLDER DOWNLOADS TERPUSAT (Aman dibersihkan)
│   ├── pip_cache/        # Cache file installer library Python (.whl)
│   ├── models/           # File bobot model AI (Whisper, Kokoro, Qwen, dll.)
│   └── torch/            # Cache model PyTorch
├── start.bat              # Menu utama launcher
├── setup.bat              # Skrip setup otomatis
├── run-desktop.bat        # Shortcut langsung Desktop App
├── run-web.bat            # Shortcut langsung Web App
├── run-server.bat         # Shortcut langsung Backend Server
└── clean-downloads.bat    # 🧹 Skrip pembersih disk & cache 1-klik
```

### Cara Membersihkan Disk:
Jalankan file **`clean-downloads.bat`** (atau pilih menu `[6]` di `start.bat`). Anda akan melihat rincian ukuran file dan dapat memilih:
- Hapus cache pip saja (sangat aman, hanya file installer sementara).
- Hapus cache model AI (model akan diunduh ulang hanya jika dipakai kembali).
- Hapus semua isi folder downloads.

---

## 5. Fitur-Fitur Unggulan

1. **8 Engine Sintesis Suara (TTS)**:
   - **Qwen3-TTS**: Kloning multilingual kualitas studio dan kontrol instruksi gaya bicara.
   - **Qwen CustomVoice & VoiceDesign**: Mendesain suara baru hanya dari deskripsi teks tanpa audio referensi.
   - **Kokoro**: Sangat ringan (model 82MB), sangat cepat bahkan di prosesor CPU biasa, dengan 50+ pilihan suara siap pakai.
   - **Chatterbox Multilingual & Turbo**: Mendukung 23 bahasa dan tag emosi percakapan seperti `[laugh]`, `[sigh]`.
   - **LuxTTS & HumeAI TADA**: Audio 48kHz beresolusi tinggi dan model wicara berdurasi panjang.

2. **Dikte Suara Global (Push-to-Talk STT)**:
   - Tekan shortcut keyboard di aplikasi apa pun (Notepad, Word, browser, kode editor), bicara melalui mikrofon, dan teks akan otomatis tertranskripsi via model Whisper lalu di-paste secara otomatis.

3. **Efek Audio DSP Profesional**:
   - Efek pasca-pemrosesan bawaan (Spotify Pedalboard): Reverb, Chorus, Delay, Kompresor dinamika, Equalizer filter, dan Pitch Shift semitone.

4. **Konektivitas Agen AI (MCP Server)**:
   - Dilengkapi tool Model Context Protocol (`voicebox_speak`) agar asisten AI seperti Claude Code, Cursor, atau Cline dapat berbicara kepada Anda dengan suara kloningan Anda sendiri.

---

## 6. Troubleshooting & Solusi Error

### 1. Masalah Force-Close saat Menjalankan `setup.bat`
* **Penyebab**: Karakter tanda kurung atau titik pada teks skrip Windows batch lama dapat memicu error internal `. was unexpected at this time`.
* **Solusi**: Skrip `setup.bat` telah diperbarui dengan struktur *flat labels* bebas tanda kurung bersarang dan dilengkapi penahan jeda (`pause`) di setiap akhir proses.

### 2. Error `Python 3.12 tidak ditemukan`
* **Penyebab**: Proyek ini mewajibkan Python 3.12. Versi 3.13 dan 3.14 belum didukung oleh pustaka audio PyTorch/Numba.
* **Solusi**: Jalankan perintah berikut di PowerShell untuk memasang Python 3.12 otomatis via `uv`:
  ```powershell
  uv python install 3.12
  ```

### 3. Port 17493 Sudah Terpakai / Bentrok
* Jika backend gagal menyala karena port bentrok, Anda dapat memeriksa atau mematikan proses yang memakai port tersebut melalui PowerShell:
  ```powershell
  Get-Process -Id (Get-NetTCPConnection -LocalPort 17493).OwningProcess | Stop-Process -Force
  ```

### 4. Menu [1] Desktop Tidak Muncul Apa-apa / Langsung Tertutup
* **Penyebab**: Aplikasi desktop Voicebox dibangun menggunakan **Tauri v2 (Rust)**. Pada mode pengembangan (*source code*), perintah `bun run tauri dev` membutuhkan **Rust Toolchain (`cargo` dan `rustc`)** terpasang di Windows untuk mengompilasi kode native Rust. Jika komputer belum terpasang Rust, perintah akan langsung berhenti dengan pesan `cargo metadata: program not found`.
* **Solusi Instan (Sangat Direkomendasikan)**:
  - Gunakan **Mode Web (Menu [3] / `run-web.bat`)**.
  - **100% Fitur Sama Persis**: Kloning Suara, TTS Kokoro/Qwen, Diktasi STT, Efek Pedalboard, dan Input Gemini Pro.
  - **TIDAK MEMBUTUHKAN RUST SAMA SEKALI**: Langsung terbuka di browser Anda (Chrome/Edge/Brave).
* **Solusi Jika Tetap Ingin Desktop Native**:
  - Pasang Rust melalui situs resmi: [https://rustup.rs](https://rustup.rs) atau jalankan `winget install Rustlang.Rustup` di PowerShell, lalu restart terminal Anda.

---

## 7. Panduan Adopsi & Legalitas Lisensi MIT

> **Pertanyaan Umum:** *"Karena proyek ini hasil forking dari GitHub orang lain, apakah bisa saya adopsi sesuai kebutuhan saya? Apakah lisensinya bisa menggunakan nama saya tanpa menyalahi aturan?"*

### Jawabannya: **BISA 100%!**

Proyek ini dilisensikan di bawah **MIT License** ([`LICENSE`](file:///c:/Users/ASUS/Documents/Web%20Dev/improving/voiceclone/LICENSE)). Lisensi MIT adalah salah satu lisensi open-source paling bebas dan ramah bisnis di dunia.

### A. Hak yang Anda Miliki:
1. **Hak Modifikasi Bebas**: Anda berhak mengubah antarmuka, menghapus fitur yang tidak dibutuhkan, menambahkan engine baru, atau merombak arsitekturnya.
2. **Hak Adopsi & Rebranding**: Anda berhak mengubah nama merek (misal mengubah nama dari *Voicebox* menjadi *Studio Suara AI Saya* atau nama produk Anda).
3. **Hak Komersial & Privat**: Anda boleh menggunakannya untuk keperluan internal perusahaan, produk komersial, maupun layanan SaaS berbayar.
4. **Hak Distribusi**: Anda boleh mendistribusikan ulang kode sumber maupun aplikasi hasil kompilasi binary (`.exe`).

### B. Satu-Satunya Aturan Wajib Lisensi MIT (*The Golden Rule*):
Anda **TIDAK BOLEH MENGHAPUS** pernyataan hak cipta (*copyright notice*) dan izin lisensi asli milik pembuat awal.

### C. Cara Menambahkan Nama / Hak Cipta Anda Sendiri:
Anda **sangat diperbolehkan** mencantumkan nama Anda atau organisasi Anda untuk modifikasi (*derivative works*) yang Anda buat. Format standar industri yang diakui secara hukum adalah:

```text
MIT License

Copyright (c) 2026 [Nama Anda / Nama Organisasi Anda] (untuk modifikasi dan adopsi)
Copyright (c) 2026 Voicebox Contributors (proyek sumber asli)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY...
```

Dengan mencantumkan format di atas pada file `LICENSE`, Anda:
- ✅ Sepenuhnya legal dan aman secara hukum.
- ✅ Menghargai pembuat asli proyek *upstream*.
- ✅ Memiliki hak cipta atas seluruh kode dan penyesuaian baru yang Anda bangun.

---

## 8. Panduan Integrasi Google Gemini Pro & Unduh Model LLM Lokal

Voicebox mendukung sistem **Hybrid LLM Intelligence**: menggunakan kecerdasan cloud (Google Gemini Pro) tanpa membebani laptop, atau model lokal offline (Qwen 2.5) saat tanpa internet.

### A. Memasang API Key Google Gemini Pro di Tampilan (Tanpa `.env`)
Anda **tidak perlu** mengedit file `.env` manual. Pasang API Key langsung di aplikasi:
1. Buka Voicebox (Desktop atau Web).
2. Buka menu **Settings** -> Tab **Captures** -> Bagian **Custom LLM Endpoint**.
3. Masukkan konfigurasi resmi Google AI Studio:
   - **Endpoint URL**: `https://generativelanguage.googleapis.com/v1beta/openai`
   - **Model Name**: `gemini-1.5-pro` (atau `gemini-2.0-flash` untuk respon super cepat)
   - **API Key**: Tempelkan API Key Google AI Studio Anda (`AIzaSy...`)
4. Data akan otomatis tersimpan aman di database lokal Anda.

### B. Mengunduh & Memperbarui Model LLM Lokal Offline
Jika ingin mengunduh model offline, jalankan menu `[6]` di `start.bat` atau *double-click* **`download-models.bat`**:
- **Qwen2.5-1.5B-Instruct** (*Rekomendasi Utama*): Seimbang antara kecepatan dan kecerdasan merapikan diktasi.
- **Qwen2.5-0.5B-Instruct**: Sangat ringan untuk laptop tanpa VGA/GPU.
- **Fitur Buka Browser**: Anda bisa memilih opsi buka tautan Hugging Face di browser untuk mengunduh file secara manual jika diinginkan.
- **Penyimpanan Terpusat**: Seluruh model otomatis disimpan di folder `downloads\models\`.

---

## 9. Roadmap Pengembangan & Perancangan Monorepo

Dokumentasi spesifikasi lengkap perancangan monorepo (Turborepo + Bun) dan pelacakan milestone masa depan dapat dipelajari pada:
- [`PRD.md`](./PRD.md) - Product Requirements Document resmi Voicebox Next-Gen.
- [`.agents/context/session-state.md`](./.agents/context/session-state.md) - Single Source of Truth status sesi dan arsitektur terkunci.

