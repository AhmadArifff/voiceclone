@echo off
title Voicebox - Desktop App

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

where bun >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Bun tidak ditemukan di PATH!
    echo Jalankan setup.bat terlebih dahulu untuk menginstal Bun.
    pause
    exit /b 1
)

REM 1. Cek atau jalankan backend server
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Menjalankan Backend Server di background...
    start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
    timeout /t 3 /nobreak >nul
) else (
    echo [OK] Backend server sudah aktif di port 17493.
)

REM 2. Pastikan placeholder binaries dev sudah siap
node "%ROOT_DIR%scripts\setup-dev-sidecar.js" >nul 2>&1

REM 3. Jalankan Tauri Desktop
echo [INFO] Menjalankan Tauri desktop application...
cd /d "%ROOT_DIR%tauri"
bun run tauri dev
