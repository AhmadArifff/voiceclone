# Voicebox Agentic Workspace (`.agents/`)

Selamat datang di direktori konfigurasi agen lokal Voicebox. Direktori ini menyimpan kumpulan **Skills** dan panduan arsitektur yang digunakan oleh AI coding agents (Antigravity, Cursor, Claude Code, Cline, dll.) untuk mengembangkan dan memelihara ekosistem Voicebox secara otonom dan konsisten.

---

## 🛠️ Katalog Skill Terdaftar (`.agents/skills/`)

| Skill | Fokus & Lingkup | Kapan Digunakan |
|---|---|---|
| [`add-tts-engine`](./skills/add-tts-engine/SKILL.md) | Integrasi Model TTS Baru | Saat menambahkan engine TTS baru (Fase 0 audit dependensi, backend protocol, frontend wiring, PyInstaller bundle, hingga frozen-build). |
| [`audio-dsp-pipeline`](./skills/audio-dsp-pipeline/SKILL.md) | Pemrosesan Audio DSP & Efek | Saat memodifikasi atau menambahkan efek audio (Spotify Pedalboard: reverb, chorus, delay, compressor, pitch shift), normalisasi RMS, trimming silence, dan crossfade chunking. |
| [`tauri-desktop-audio`](./skills/tauri-desktop-audio/SKILL.md) | Desktop App & Native Audio (Rust) | Saat mengerjakan lapisan desktop Tauri 2, global hotkey chord matcher (`keytap`), active window focus capture, clipboard synthetic keystrokes paste, dan manajemen sidecar Python. |
| [`voicebox-backend`](./skills/voicebox-backend/SKILL.md) | Backend FastAPI & AI Inference | Saat mengedit backend Python 3.12+, REST routes, serial GPU task queue, SQLAlchemy SQLite models, deteksi akselerasi GPU (CUDA/MLX/ROCm), dan kepatuhan `STYLE_GUIDE.md`. |
| [`voicebox-frontend`](./skills/voicebox-frontend/SKILL.md) | Frontend UI React & Wavesurfer | Saat mengembangkan komponen antarmuka React 18, WaveSurfer.js waveform visualizer, TanStack Query cache invalidation, Zustand stores, dan Tailwind CSS. |
| [`draft-release-notes`](./skills/draft-release-notes/SKILL.md) | Rilis & Dokumentasi | Saat menyusun draft catatan rilis pada bagian `[Unreleased]` di `CHANGELOG.md` berdasarkan commit diff sejak tag terakhir. |
| [`release-bump`](./skills/release-bump/SKILL.md) | Eksekusi Rilis Versi | Saat memfinalisasi rilis produksi: stamping versi, menjalankan `bumpversion`, dan membuat commit serta git tag rilis. |
| [`triage-prs`](./skills/triage-prs/SKILL.md) | Triase Pull Request | Saat melakukan tinjauan dan penggabungan (merge loop) batch pull request sebelum rilis baru. |

---

## 🏗️ Standar Arsitektur Singkat

1. **Frontend**: Vite + React 18 + Tailwind CSS + Radix UI + Motion di folder `app/`.
2. **Desktop Shell**: Tauri 2.0 (Rust) di folder `tauri/src-tauri/` yang menangani low-level audio I/O dan hotkeys.
3. **Backend Server**: FastAPI (Python 3.12) di folder `backend/`, berjalan di `localhost:17493` sebagai sidecar process.
4. **Audio DSP**: Spotify Pedalboard + librosa + soundfile di `backend/utils/`.
5. **Quality Control**: Biome (`bun run check:fix`) untuk frontend/root dan Ruff (`ruff check backend/`) untuk backend.
