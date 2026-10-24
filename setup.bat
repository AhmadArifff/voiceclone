@echo off
setlocal enabledelayedexpansion
title Voicebox - Setup and Dependency Installer

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

REM Konfigurasi folder download terpusat agar mudah dibersihkan
set "DOWNLOADS_DIR=%ROOT_DIR%downloads"
if not exist "%DOWNLOADS_DIR%" mkdir "%DOWNLOADS_DIR%"
if not exist "%DOWNLOADS_DIR%\models" mkdir "%DOWNLOADS_DIR%\models"
if not exist "%DOWNLOADS_DIR%\pip_cache" mkdir "%DOWNLOADS_DIR%\pip_cache"
if not exist "%DOWNLOADS_DIR%\torch" mkdir "%DOWNLOADS_DIR%\torch"

set "PIP_CACHE_DIR=%DOWNLOADS_DIR%\pip_cache"
set "VOICEBOX_MODELS_DIR=%DOWNLOADS_DIR%\models"
set "HF_HOME=%DOWNLOADS_DIR%\huggingface"
set "HF_HUB_CACHE=%DOWNLOADS_DIR%\models"
set "TORCH_HOME=%DOWNLOADS_DIR%\torch"

echo ======================================================================
echo           VOICEBOX - AUTOMATED SETUP AND DEPENDENCY INSTALLER
echo ======================================================================
echo [INFO] Folder unduhan terpusat di: %DOWNLOADS_DIR%
echo       (Semua file cache dan model akan disimpan di sini)
echo.

REM ----------------------------------------------------------------------
REM 1. Periksa / Install Bun
REM ----------------------------------------------------------------------
echo [1/5] Memeriksa Bun JavaScript Runtime...

set "BUN_EXE="
if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "BUN_EXE=%USERPROFILE%\.bun\bin\bun.exe"
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
) else (
    where bun >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set "BUN_EXE=bun"
    )
)

if not defined BUN_EXE (
    echo [INFO] Bun belum terinstal. Mengunduh dan menginstal Bun via PowerShell...
    powershell -NoProfile -Command "irm bun.sh/install.ps1 | iex"
    if exist "%USERPROFILE%\.bun\bin\bun.exe" (
        set "BUN_EXE=%USERPROFILE%\.bun\bin\bun.exe"
        set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
    ) else (
        echo [ERROR] Gagal menginstal Bun otomatis. Silakan instal manual dari https://bun.sh
        pause
        exit /b 1
    )
)

for /f "tokens=*" %%v in ('"%BUN_EXE%" --version') do echo [OK] Bun terdeteksi: v%%v

echo.
REM ----------------------------------------------------------------------
REM 2. Siapkan Python 3.12 Virtual Environment
REM ----------------------------------------------------------------------
echo [2/5] Menyiapkan Python 3.12 Virtual Environment (backend\venv)...
set "VENV_DIR=%ROOT_DIR%backend\venv"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"

if exist "%PYTHON_EXE%" (
    for /f "tokens=*" %%v in ('"%PYTHON_EXE%" --version') do echo [OK] Virtual Environment siap: %%v
) else (
    echo [INFO] Mencari / menyiapkan interpreter Python 3.12...
    set "FOUND_PY="

    REM Cek dan gunakan uv jika tersedia
    where uv >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [INFO] Memeriksa Python 3.12 via uv...
        uv python install 3.12 >nul 2>&1
        uv venv "%VENV_DIR%" --python 3.12
        if exist "%PYTHON_EXE%" set "FOUND_PY=uv"
    )

    REM Cek via py launcher jika uv belum membuat venv
    if not defined FOUND_PY (
        where py >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            py -3.12 -c "import sys" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo [INFO] Membuat venv menggunakan 'py -3.12'...
                py -3.12 -m venv "%VENV_DIR%"
                if exist "%PYTHON_EXE%" set "FOUND_PY=py"
            )
        )
    )

    REM Cek apakah python di PATH adalah 3.12
    if not defined FOUND_PY (
        where python >nul 2>&1
        if !ERRORLEVEL! EQU 0 (
            python -c "import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo [INFO] Membuat venv menggunakan python di PATH...
                python -m venv "%VENV_DIR%"
                if exist "%PYTHON_EXE%" set "FOUND_PY=python"
            )
        )
    )

    if not exist "%PYTHON_EXE%" (
        echo.
        echo [ERROR] Python 3.12 tidak ditemukan!
        echo Voicebox mewajibkan Python 3.12 (3.13/3.14 belum didukung dependensi audio PyTorch).
        echo Pilihan solusi:
        echo   1. Jalankan: uv python install 3.12
        echo   2. Atau jalankan: winget install -e --id Python.Python.3.12
        echo.
        pause
        exit /b 1
    )
    for /f "tokens=*" %%v in ('"%PYTHON_EXE%" --version') do echo [OK] Virtual Environment berhasil dibuat: %%v
)

echo.
REM ----------------------------------------------------------------------
REM 3. Instal Dependensi Python (PyTorch CUDA / CPU + TTS Engines)
REM ----------------------------------------------------------------------
echo [3/5] Menginstal dependensi Python ke backend\venv...
echo [INFO] Cache wheel diarahkan ke: %PIP_CACHE_DIR%
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" --upgrade pip -q

echo [INFO] Mendeteksi hardware GPU...
powershell -NoProfile -Command "$g = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name; Write-Host ('GPU terdeteksi: ' + ($g -join ', ')); if ($g -match 'NVIDIA') { exit 10 } elseif ($g -match 'Arc') { exit 20 } else { exit 30 }"
set "GPU_DETECT_CODE=%ERRORLEVEL%"

if %GPU_DETECT_CODE% EQU 10 (
    echo [INFO] GPU NVIDIA terdeteksi - menginstal PyTorch dengan CUDA 12.8...
    "%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
) else if %GPU_DETECT_CODE% EQU 20 (
    echo [INFO] GPU Intel Arc terdeteksi - menginstal PyTorch dengan dukungan XPU...
    "%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
    "%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" intel-extension-for-pytorch --index-url https://download.pytorch.org/whl/xpu
) else (
    echo [INFO] GPU NVIDIA tidak terdeteksi - menggunakan PyTorch versi CPU...
    "%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" torch torchvision torchaudio
)

echo [INFO] Menginstal dependensi backend (requirements.txt)...
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" -r "%ROOT_DIR%backend\requirements.txt"

echo [INFO] Menginstal engine TTS pihak ketiga...
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" --no-deps chatterbox-tts
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" --no-deps hume-tada
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" --no-deps omnivoice
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" git+https://github.com/QwenLM/Qwen3-TTS.git
"%PYTHON_EXE%" -m pip install --cache-dir "%PIP_CACHE_DIR%" pyinstaller ruff pytest pytest-asyncio openai -q

echo.
REM ----------------------------------------------------------------------
REM 4. Instal Dependensi JavaScript (Bun)
REM ----------------------------------------------------------------------
echo [4/5] Menginstal paket JavaScript workspace via Bun...
"%BUN_EXE%" install

echo.
REM ----------------------------------------------------------------------
REM 5. Siapkan Placeholder Sidecar Binaries untuk Dev
REM ----------------------------------------------------------------------
echo [5/5] Membuat placeholder sidecar binaries untuk mode dev Tauri...
node "%ROOT_DIR%scripts\setup-dev-sidecar.js"

echo.
echo ======================================================================
echo          SETUP SELESAI! SEMUA DEPENDENSI SIAP DIGUNAKAN.
echo ======================================================================
echo [TIPS] Semua file unduhan/cache tersimpan rapi di: %DOWNLOADS_DIR%
echo       Anda bisa membersihkan folder ini kapan saja via clean-downloads.bat
echo.
echo Anda sekarang bisa menjalankan:
echo   - start.bat        (Menu utama launcher)
echo   - run-desktop.bat  (Langsung menjalankan Voicebox Desktop)
echo   - run-server.bat   (Langsung menjalankan Backend Server)
echo.
pause
