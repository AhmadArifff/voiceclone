@echo off
setlocal

title Voicebox - Model Download dan Manager Hub
color 0B

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "MODELS_DIR=%PROJECT_DIR%\downloads\models"
set "PYTHON_EXE=%PROJECT_DIR%\backend\venv\Scripts\python.exe"

if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

:MENU
cls
echo ===============================================================================
echo                VOICEBOX AI - MODEL DOWNLOADER DAN REPO MANAGER
echo ===============================================================================
echo  Direktori Model: %MODELS_DIR%
echo ===============================================================================
echo.
echo  PILIH MODEL LLM DAN TTS YANG INGIN DIUNDUH ATAU DIBUKA DI BROWSER:
echo.
echo  [1] Qwen2.5-1.5B-Instruct - Rekomendasi Utama (Seimbang Cepat dan Cerdas)
echo  [2] Qwen2.5-0.5B-Instruct - Ultra Ringan (Cocok untuk Laptop tanpa GPU)
echo  [3] Qwen2.5-3B-Instruct   - Cerdas Tinggi (Membutuhkan GPU 6GB+ VRAM)
echo  [4] Llama-3.2-1B-Instruct - Alternatif Meta AI (Cepat dan Stabil)
echo  [5] Kokoro-82M TTS        - Model Suara Utama Voicebox (Kloning Cepat)
echo.
echo  PILIHAN LAINNYA:
echo  [6] Buka Folder Unduhan Model di File Explorer
echo  [7] Cek Model yang Sudah Terunduh
echo  [0] Keluar ke Menu Utama
echo.
echo ===============================================================================
set "CHOICE="
set /p "CHOICE=Pilih nomor [0-7]: "

if "%CHOICE%"=="" goto MENU

if "%CHOICE%"=="1" goto MODEL_QWEN_15
if "%CHOICE%"=="2" goto MODEL_QWEN_05
if "%CHOICE%"=="3" goto MODEL_QWEN_3
if "%CHOICE%"=="4" goto MODEL_LLAMA_1
if "%CHOICE%"=="5" goto MODEL_KOKORO
if "%CHOICE%"=="6" goto OPEN_FOLDER
if "%CHOICE%"=="7" goto CHECK_MODELS
if "%CHOICE%"=="0" goto EXIT_SCRIPT

echo [ERROR] Pilihan tidak valid. Silakan coba lagi.
ping 127.0.0.1 -n 2 >nul
goto MENU

:: -------------------------------------------------------------------------
:MODEL_QWEN_15
set "REPO_ID=Qwen/Qwen2.5-1.5B-Instruct"
set "MODEL_NAME=Qwen2.5 1.5B Instruct"
set "WEB_URL=https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct"
goto PROMPT_ACTION

:MODEL_QWEN_05
set "REPO_ID=Qwen/Qwen2.5-0.5B-Instruct"
set "MODEL_NAME=Qwen2.5 0.5B Instruct"
set "WEB_URL=https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct"
goto PROMPT_ACTION

:MODEL_QWEN_3
set "REPO_ID=Qwen/Qwen2.5-3B-Instruct"
set "MODEL_NAME=Qwen2.5 3B Instruct"
set "WEB_URL=https://huggingface.co/Qwen/Qwen2.5-3B-Instruct"
goto PROMPT_ACTION

:MODEL_LLAMA_1
set "REPO_ID=meta-llama/Llama-3.2-1B-Instruct"
set "MODEL_NAME=Llama 3.2 1B Instruct"
set "WEB_URL=https://huggingface.co/meta-llama/Llama-3.2-1B-Instruct"
goto PROMPT_ACTION

:MODEL_KOKORO
set "REPO_ID=hexgrad/Kokoro-82M"
set "MODEL_NAME=Kokoro-82M TTS Engine"
set "WEB_URL=https://huggingface.co/hexgrad/Kokoro-82M"
goto PROMPT_ACTION

:: -------------------------------------------------------------------------
:PROMPT_ACTION
cls
echo ===============================================================================
echo  MODEL TERPILIH: %MODEL_NAME%
echo  Hugging Face Repo: %REPO_ID%
echo ===============================================================================
echo.
echo  Bagaimana Anda ingin memproses model ini?
echo.
echo  [1] Unduh Otomatis Sekarang via Terminal (Download langsung ke downloads\models)
echo  [2] Buka Halaman Resmi Hugging Face di Browser (Unduh manual via web)
echo  [3] Kembali ke Menu Pilihan Model
echo.
set /p "ACTION=Pilih aksi [1-3]: "

if "%ACTION%"=="1" goto DOWNLOAD_AUTO
if "%ACTION%"=="2" goto OPEN_BROWSER
if "%ACTION%"=="3" goto MENU

echo [ERROR] Pilihan tidak valid.
ping 127.0.0.1 -n 2 >nul
goto PROMPT_ACTION

:: -------------------------------------------------------------------------
:OPEN_BROWSER
echo.
echo [INFO] Membuka %WEB_URL% di peramban web default Anda...
start "" "%WEB_URL%"
echo.
echo [PETUNJUK UNDUH MANUAL]
echo 1. Di halaman Hugging Face, klik tab Files and versions.
echo 2. Anda dapat mendownload file model (.safetensors, config.json, tokenizer.json).
echo 3. Simpan atau ekstrak ke folder: %MODELS_DIR%
echo.
pause
goto MENU

:: -------------------------------------------------------------------------
:DOWNLOAD_AUTO
echo.
if not exist "%PYTHON_EXE%" goto NO_PYTHON

echo ===============================================================================
echo [PROSES] Memulai unduhan otomatis untuk: %REPO_ID%
echo Target folder: %MODELS_DIR%
echo Mohon tunggu, proses ini bergantung pada kecepatan internet Anda...
echo ===============================================================================
echo.

"%PYTHON_EXE%" -c "from huggingface_hub import snapshot_download; print('Mengunduh: %REPO_ID%...'); snapshot_download(repo_id='%REPO_ID%', cache_dir=r'%MODELS_DIR%'); print('Selesai!')"

if %errorlevel% neq 0 goto DOWNLOAD_FAIL

echo.
echo ===============================================================================
echo [SUKSES] Model %MODEL_NAME% berhasil diunduh dan tersimpan di:
echo %MODELS_DIR%
echo ===============================================================================
echo.
pause
goto MENU

:DOWNLOAD_FAIL
echo.
echo ===============================================================================
echo [PERINGATAN] Gagal mengunduh otomatis. Kemungkinan koneksi internet terputus
echo atau repositori membutuhkan Hugging Face Token untuk model berlisensi.
echo Anda dapat mencoba opsi [2] untuk mengunduh langsung via Browser.
echo ===============================================================================
echo.
pause
goto MENU

:NO_PYTHON
echo [ERROR] Python environment belum siap di %PYTHON_EXE%!
echo Silakan jalankan setup.bat terlebih dahulu untuk menyiapkan dependensi.
echo.
pause
goto MENU

:: -------------------------------------------------------------------------
:OPEN_FOLDER
echo.
echo [INFO] Membuka folder %MODELS_DIR% di File Explorer...
start "" "%MODELS_DIR%"
goto MENU

:: -------------------------------------------------------------------------
:CHECK_MODELS
cls
echo ===============================================================================
echo               STATUS MODEL DI FOLDER DOWNLOADS\MODELS
echo ===============================================================================
echo Lokasi: %MODELS_DIR%
echo.
dir "%MODELS_DIR%" /B
echo.
echo ===============================================================================
pause
goto MENU

:: -------------------------------------------------------------------------
:EXIT_SCRIPT
exit /b 0
