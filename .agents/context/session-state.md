# Session State & Architectural Memory (`.agents/context/session-state.md`)

> **Single Source of Truth (SSOT)**: Dokumen ini mengunci *active goal*, status sub-tugas, keputusan arsitektur yang sudah disepakati, serta riwayat perubahan development agar agen AI (Antigravity, Cursor, Claude Code, Cline) dan tim developer tidak mengalami *context drift* di seluruh sesi pengerjaan.

---

## 1. Metadata Sesi & Lingkungan

- **Project Name**: Voicebox Next-Gen (`jamiepine/voicebox` derivative)
- **Maintainer / Owner**: Ahmad Arif
- **Local Time**: 2026-10-24
- **Operating System**: Windows 11 (64-bit)
- **Python Runtime**: Python 3.12.13 (`backend\venv\Scripts\python.exe`)
- **JavaScript Runtime**: Bun 1.4.4 (`C:\Users\ASUS\.bun\bin\bun.exe`)
- **Dev Servers**:
  - FastAPI Server: `http://127.0.0.1:17493`
  - Vite Frontend: `http://localhost:5173`
- **Lisensi Proyek**: MIT License (Atribusi pengembang turunan resmi: Ahmad Arif)

---

## 2. Established & Locked Constraints (Keputusan Mutlak)

1. **Aturan Skrip Windows CMD**:
   - DILARANG menggunakan tanda kurung yang tidak diescape di dalam blok `if (...)` pada file `.bat` (seperti `(%VAR%) tidak ditemukan!` atau `(3.13/3.14...).`).
   - Seluruh logika percabangan `.bat` wajib menggunakan arsitektur label datar (`goto :LABEL`) guna mencegah error fatal `unexpected at this time`.
2. **Higienitas Penyimpanan (`downloads/`)**:
   - Seluruh cache model AI, wheel Python, dan cache PyTorch WAJIB diisolasi ke dalam folder `./downloads/` (`downloads\models`, `downloads\pip_cache`, `downloads\torch`). Dilarang menulis cache ke partisi root `C:\` pengguna.
3. **Penyimpanan API Key Gemini di UI (Bukan di `.env`)**:
   - API Key Google AI Studio (Gemini Pro) harus diinput dan dikelola langsung melalui tampilan antarmuka (UI Settings -> Captures / Refinement), disimpan di SQLite tabel `settings`.
   - Tidak memaksa pengguna untuk membuat atau mengedit file `.env` manual.
4. **Auto-Launch Web Browser**:
   - Menjalankan mode web via `start.bat` (Opsi 3) atau `run-web.bat` harus secara otomatis memicu pembukaan browser default ke `http://localhost:5173`.
5. **Kedaulatan Lisensi MIT**:
   - File `LICENSE` asli tetap dipertahankan utuh; file `GUIDE_BOOK.md` dan `PRD.md` mencantumkan hak cipta turunan resmi.

---

## 3. Active Goal & Status Sub-Tugas

| Sub-Tugas | Status | Deskripsi & File Terdampak |
|---|---|---|
| **Audit Arsitektur & Skill Catalog** | ✅ SELESAI | Review seluruh stack, buat 8 skill di `.agents/skills/`. |
| **Windows Native Batch Hub** | ✅ SELESAI | Dibuat `start.bat`, `setup.bat`, `run-server.bat`, `run-web.bat`, `run-desktop.bat`. |
| **Perbaikan Bug Sintaks CMD** | ✅ SELESAI | Memperbaiki error `tidak was unexpected` di `run-server.bat` dan `. was unexpected` di `setup.bat`. |
| **Isolasi Folder Downloads & Cleaner** | ✅ SELESAI | Dibuat `clean-downloads.bat` untuk inspeksi ukuran disk dan pembersihan aman. |
| **Browser Auto-Launch** | ✅ SELESAI | Menambahkan `start http://localhost:5173` ke `run-web.bat` dan `start.bat`. |
| **Model Downloader & Browser Link Hub** | ✅ SELESAI | Dibuat `download-models.bat` untuk unduhan otomatis terminal atau buka browser HF. |
| **Product Requirements Document (PRD)** | ✅ SELESAI | Dibuat [`PRD.md`](../../PRD.md) mencakup rencana Monorepo & roadmap Fase 1-4. |
| **UI-Managed Gemini Pro Preset** | ⏳ ROADMAP | Menambahkan tombol preset "Google Gemini Pro" di UI (`CapturesPage.tsx`). |
| **Monorepo Migration** | ⏳ ROADMAP | Restrukturisasi ke `apps/` dan `packages/` via Turborepo & Bun workspaces. |

---

## 4. Architectural Decision Records (ADR)

### ADR-001: Integrasi Google Gemini Pro via OpenAI-Compatible Endpoint
- **Konteks**: Pengguna berlangganan Gemini Pro dan memiliki Google AI Studio API Key. Voicebox membutuhkan model LLM untuk merapikan teks diktasi dan personalisasi suara.
- **Keputusan**: Menggunakan endpoint resmi OpenAI-compatible dari Google:
  `https://generativelanguage.googleapis.com/v1beta/openai` dengan model `gemini-1.5-pro` atau `gemini-2.0-flash`.
- **Rasional**: Backend Voicebox (`backend/backends/openai_compat_backend.py`) sudah mendukung protokol `/chat/completions` secara native. Tanpa perlu install library tambahan, Gemini Pro langsung aktif dan menghemat VRAM serta penyimpanan harddisk lokal (menghemat ~3GB-8GB).

### ADR-002: Model LLM Lokal Terpilih (Qwen2.5-1.5B Sweet Spot)
- **Konteks**: Pengguna ingin opsi offline jika tidak ada koneksi internet.
- **Keputusan**: Menetapkan `Qwen/Qwen2.5-1.5B-Instruct` sebagai rekomendasi lokal utama, dengan fallback `Qwen/Qwen2.5-0.5B-Instruct` untuk perangkat berspesifikasi rendah.
- **Rasional**: Seri Qwen2.5 memiliki pemahaman bahasa multibahasa (termasuk Bahasa Indonesia dan Inggris) terbaik di kelas bobot kecil, dengan latensi inferensi di bawah 1 detik pada CPU.

### ADR-003: Restrukturisasi Monorepo Bertahap (Zero Breaking Changes)
- **Konteks**: Struktur saat ini memiliki ketergantungan rapuh `../../app/src/...` pada `web/src/main.tsx`.
- **Keputusan**: Migrasi akan dilakukan secara bertahap (Fase 3 pada PRD), dimulai dari ekstraksi `@voicebox/ui` dan `@voicebox/core`, memastikan desktop Tauri dan Web tetap fungsional di setiap langkah.

### ADR-004: Rust Toolchain Guardrail untuk Desktop Mode
- **Konteks**: Mode desktop (`tauri dev`) membutuhkan compiler Rust (`cargo`) terpasang secara lokal untuk mengompilasi binding native Tauri. Pada komputer tanpa Rust, perintah langsung keluar dengan error `cargo metadata: program not found`.
- **Keputusan**: Menyematkan deteksi otomatis `where cargo` pada `start.bat` dan `run-desktop.bat`. Jika Rust belum terpasang, sistem menampilkan dialog panduan yang jelas dan menawarkan pengalihan otomatis 1-klik ke Mode Web (`run-web.bat`), yang memiliki fitur 100% identik tanpa ketergantungan compiler Rust/C++.
