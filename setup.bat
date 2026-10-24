@echo off
setlocal enabledelayedexpansion
title Voicebox - Setup and Dependency Installer

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

echo ======================================================================
echo           VOICEBOX - AUTOMATED SETUP AND DEPENDENCY INSTALLER
echo ======================================================================
echo.

REM ----------------------------------------------------------------------
REM 1. Periksa / Install Bun
REM ----------------------------------------------------------------------
echo [1/5] Memeriksa Bun JavaScript Runtime...
if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

where bun >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Bun belum terinstal. Mengunduh dan menginstal Bun via PowerShell...
    powershell -NoProfile -Command "irm bun.sh/install.ps1 | iex"
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
    where bun >nul 2>&1
    if !ERRORLEVEL% NEQ 0 (
        echo [ERROR] Gagal menginstal Bun otomatis. Silakan instal manual dari https://bun.sh
        pause
        exit /b 1
    )
    echo [OK] Bun berhasil diinstal!
) else (
    for /f "tokens=*" %%v in ('bun --version') do echo [OK] Bun terdeteksi: v%%v
)

echo.
REM ----------------------------------------------------------------------
REM 2. Siapkan Python 3.12 Virtual Environment
REM ----------------------------------------------------------------------
echo [2/5] Menyiapkan Python 3.12 Virtual Environment (backend\venv)...
set "VENV_DIR=%ROOT_DIR%backend\venv"
set "PYTHON_EXE=%VENV_DIR%\Scripts\python.exe"

if exist "%PYTHON_EXE%" (
    echo [OK] Virtual Environment sudah ada di backend\venv.
) else (
    echo [INFO] Mencari interpreter Python 3.12...
    set "FOUND_PY="

    REM Cek via uv
    where uv >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo [INFO] Menggunakan 'uv' untuk membuat venv Python 3.12...
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
        echo   1. Jalankan: winget install -e --id Python.Python.3.12
        echo   2. Atau instal via uv: uv python install 3.12
        echo.
        pause
        exit /b 1
    )
    echo [OK] Virtual environment Python 3.12 berhasil dibuat!
)

echo.
REM ----------------------------------------------------------------------
REM 3. Instal Dependensi Python (PyTorch CUDA / CPU + TTS Engines)
REM ----------------------------------------------------------------------
echo [3/5] Menginstal dependensi Python ke backend\venv...
"%PYTHON_EXE%" -m pip install --upgrade pip -q

echo [INFO] Mendeteksi hardware GPU...
powershell -NoProfile -Command "$g = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name; Write-Host ('GPU terdeteksi: ' + ($g -join ', ')); if ($g -match 'NVIDIA') { exit 10 } elseif ($g -match 'Arc') { exit 20 } else { exit 30 }"
set "GPU_DETECT_CODE=%ERRORLEVEL%"

if %GPU_DETECT_CODE% EQU 10 (
    echo [INFO] GPU NVIDIA terdeteksi - menginstal PyTorch dengan CUDA 12.8...
    "%PYTHON_EXE%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
) else if %GPU_DETECT_CODE% EQU 20 (
    echo [INFO] GPU Intel Arc terdeteksi - menginstal PyTorch dengan dukungan XPU...
    "%PYTHON_EXE%" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
    "%PYTHON_EXE%" -m pip install intel-extension-for-pytorch --index-url https://download.pytorch.org/whl/xpu
) else (
    echo [INFO] GPU NVIDIA tidak terdeteksi - menggunakan PyTorch versi CPU...
    "%PYTHON_EXE%" -m pip install torch torchvision torchaudio
)

echo [INFO] Menginstal dependensi backend (requirements.txt)...
"%PYTHON_EXE%" -m pip install -r "%ROOT_DIR%backend\requirements.txt"

echo [INFO] Menginstal engine TTS pihak ketiga...
"%PYTHON_EXE%" -m pip install --no-deps chatterbox-tts
"%PYTHON_EXE%" -m pip install --no-deps hume-tada
"%PYTHON_EXE%" -m pip install --no-deps omnivoice
"%PYTHON_EXE%" -m pip install git+https://github.com/QwenLM/Qwen3-TTS.git
"%PYTHON_EXE%" -m pip install pyinstaller ruff pytest pytest-asyncio openai -q

echo.
REM ----------------------------------------------------------------------
REM 4. Instal Dependensi JavaScript (Bun)
REM ----------------------------------------------------------------------
echo [4/5] Menginstal paket JavaScript workspace via Bun...
bun install

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
echo Anda sekarang bisa menjalankan:
echo   - start.bat        (Menu utama launcher)
echo   - run-desktop.bat  (Langsung menjalankan Voicebox Desktop)
echo   - run-server.bat   (Langsung menjalankan Backend Server)
echo.
