---
name: hybrid-llm-engine
description: "Use this skill for managing the Hybrid LLM Engine in Voicebox, covering Google Gemini Pro Cloud integration (via Google AI Studio OpenAI-compatible endpoint), UI-based API key management without .env, local offline model downloads (Qwen2.5, Llama 3.2), and text refinement pipeline."
---

# Hybrid LLM Engine Skill (`hybrid-llm-engine`)

Gunakan skill ini saat mengerjakan, menguji, atau memodifikasi subsistem Large Language Model (LLM) di Voicebox, baik untuk mode cloud (Google Gemini Pro) maupun model lokal offline (Qwen2.5 / Llama 3.2).

---

## 1. Arsitektur Hybrid LLM Voicebox

Voicebox menggunakan model LLM untuk dua tugas utama:
1. **Diktasi Cerdas & Refinement**: Menghilangkan kata *filler* ("uh", "um", "anu"), memperbaiki tanda baca, dan memformat teks hasil transkrip Speech-to-Text (Whisper) menjadi rapi secara instan.
2. **Personality & Prompt Shaping**: Mengubah nada bicara (formal, santai, dramatis) sebelum teks dikirimkan ke TTS Engine (Kokoro/Chatterbox).

### Dua Jalur Inferensi:
```
           +---------------------------------------------+
           |      Frontend UI: Settings -> Captures       |
           |   (Pilihan Provider: Gemini Pro vs Qwen)    |
           +---------------------------------------------+
                                  |
                                  v
                  +-------------------------------+
                  |  backend/routes/llm.py         |
                  |  POST /llm/generate           |
                  +-------------------------------+
                                  |
                  +---------------+---------------+
                  |                               |
                  v                               v
    [Cloud: Gemini Pro Provider]      [Local: Qwen2.5 PyTorch/MLX]
    OpenAICompatLLMBackend             PyTorchQwenLLMBackend
    - Endpoint: Google AI Studio       - Model: Qwen2.5-1.5B
    - Model: gemini-1.5-pro            - Cache: downloads/models/
    - API Key: Dari UI (SQLite)        - Latency: CPU/GPU lokal
    - Zero VRAM / Zero Disk            - 100% Offline / Privat
```

---

## 2. Integrasi Google Gemini Pro via UI (Tanpa `.env`)

### Parameter Endpoint Resmi Google AI Studio:
- **Base Endpoint**: `https://generativelanguage.googleapis.com/v1beta/openai`
- **Full Chat URL**: `https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`
- **Model Opsi**:
  - `gemini-1.5-pro` (Kualitas penalaran tinggi, konteks panjang)
  - `gemini-2.0-flash` (Respon ultra-cepat sub-detik, sangat ideal untuk diktasi *real-time*)
  - `gemini-1.5-flash` (Hemat kuota token)
- **Header Autentikasi**: `Authorization: Bearer <API_KEY>`

### Aturan Penyimpanan UI:
- API Key **TIDAK BOLEH** dipaksa masuk ke file `.env` sistem.
- API Key dikirim dari frontend via `PATCH /settings/captures` dengan payload `{ custom_llm_api_key: "AIza..." }`.
- Backend menyimpannya di database SQLite lokal (`backend/database/models.py:CaptureSettingsRow.custom_llm_api_key`).
- Pada response GET, backend hanya mengembalikan status boolean `custom_llm_api_key_configured: true` untuk keamanan (tidak membocorkan key asli ke log/response).

---

## 3. Manajemen Model Lokal & Sumber Unduhan

Jika pengguna memilih mode offline atau tidak memiliki koneksi internet, gunakan model yang tersimpan di `downloads/models/`:

### Model yang Didukung & Parameter:
1. **Qwen/Qwen2.5-1.5B-Instruct** (*Rekomendasi Utama*):
   - Kebutuhan RAM: ~2.5 GB
   - Kemampuan: Bahasa Indonesia & Inggris sangat fasih, pembersihan diktasi presisi.
   - Lokasi download: `downloads\models\Qwen2.5-1.5B-Instruct`
2. **Qwen/Qwen2.5-0.5B-Instruct** (*Mode Hemat*):
   - Kebutuhan RAM: ~800 MB
   - Cocok untuk laptop tanpa kartu grafis (CPU-only).
3. **Qwen/Qwen2.5-3B-Instruct** (*Mode Superior*):
   - Kebutuhan RAM/VRAM: ~6 GB.
4. **meta-llama/Llama-3.2-1B-Instruct** (*Alternatif Llama*):
   - Kebutuhan RAM: ~1.8 GB.

### Skrip Otomasi Unduhan:
- Pengguna dapat menjalankan [`download-models.bat`](../../download-models.bat) dari root proyek.
- Skrip ini menggunakan Python `huggingface_hub.snapshot_download` dengan target `cache_dir=r"%MODELS_DIR%"` atau menyediakan opsi membuka tautan web Hugging Face di browser.

---

## 4. Prosedur Pengujian (Testing Verification)

Untuk menguji apakah backend LLM aktif dengan benar:

```bash
# Test endpoint LLM via PowerShell
$body = @{
    prompt = "halo perbaiki kalimat ini: saya lagi mau makan makan siang tapi belum laper"
    system = "Kamu adalah asisten perapi teks diktasi. Buat kalimat menjadi ringkas dan tepat."
    max_tokens = 100
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:17493/llm/generate" -Method POST -Body $body -ContentType "application/json"
```

Jika sukses, endpoint akan mengembalikan JSON:
```json
{
  "text": "Saya ingin makan siang, tetapi belum merasa lapar.",
  "model_size": "gemini-1.5-pro"
}
```
