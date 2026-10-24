@echo off
setlocal enabledelayedexpansion
title Voicebox - Desktop App

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

REM Konfigurasi folder model dan cache terpusat
set "DOWNLOADS_DIR=%ROOT_DIR%downloads"
if not exist "%DOWNLOADS_DIR%\models" mkdir "%DOWNLOADS_DIR%\models"
set "VOICEBOX_MODELS_DIR=%DOWNLOADS_DIR%\models"
set "HF_HOME=%DOWNLOADS_DIR%\huggingface"
set "HF_HUB_CACHE=%DOWNLOADS_DIR%\models"
set "TORCH_HOME=%DOWNLOADS_DIR%\torch"

set "BUN_CMD=bun"
if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "BUN_CMD=%USERPROFILE%\.bun\bin\bun.exe"
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

"%BUN_CMD%" --version >nul 2>&1
if %ERRORLEVEL% EQU 0 goto BUN_OK

echo [ERROR] Bun tidak ditemukan di PATH!
echo Jalankan setup.bat terlebih dahulu untuk menginstal Bun.
pause
exit /b 1

:BUN_OK
REM 1. Periksa apakah Rust (cargo) terpasang di komputer
where cargo >nul 2>&1
if %ERRORLEVEL% EQU 0 goto RUST_OK

cls
echo ======================================================================
echo   [PERINGATAN] RUST COMPILER (CARGO) BELUM TERPASANG DI WINDOWS!
echo ======================================================================
echo   Aplikasi Desktop (Tauri) dalam mode development ini membutuhkan
echo   compiler Rust untuk membangun jendela native.
echo.
echo   SOLUSI YANG SANGAT MUDAH:
echo   Gunakan MODE WEB (run-web.bat)
echo   - 100%% FITUR SAMA: Kloning Suara, TTS Kokoro/Qwen, Diktasi, DSP Efek
echo   - Berjalan langsung di Web Browser (Chrome/Edge/Brave)
echo   - TIDAK MEMBUTUHKAN RUST ATAU C++ COMPILER SAMA SEKALI!
echo.
echo   Jika Anda tetap ingin aplikasi desktop native terkompilasi,
echo   silakan pasang Rust toolchain melalui: https://rustup.rs
echo ======================================================================
echo.
set "SWITCH_WEB=Y"
set /p "SWITCH_WEB=Apakah Anda ingin langsung membuka Mode Web sekarang? (Y/N) [Y]: "
if /i "!SWITCH_WEB!"=="Y" (
    call "%ROOT_DIR%run-web.bat"
    exit /b 0
)
pause
exit /b 1

:RUST_OK
REM 2. Cek atau jalankan backend server
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% EQU 0 goto BACKEND_OK

echo [INFO] Menjalankan Backend Server di background...
start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
timeout /t 3 /nobreak >nul

:BACKEND_OK
REM 3. Pastikan placeholder binaries dev sudah siap
node "%ROOT_DIR%scripts\setup-dev-sidecar.js" >nul 2>&1

REM 4. Jalankan Tauri Desktop
echo [INFO] Menjalankan Tauri desktop application...
cd /d "%ROOT_DIR%tauri"
"%BUN_CMD%" run tauri dev
pause
