@echo off
title Voicebox - Web UI

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

set "BUN_CMD=bun"
if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "BUN_CMD=%USERPROFILE%\.bun\bin\bun.exe"
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

"%BUN_CMD%" --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Bun tidak ditemukan di PATH atau %USERPROFILE%\.bun\bin!
    echo Jalankan setup.bat terlebih dahulu untuk menginstal Bun.
    pause
    exit /b 1
)

powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% NEQ 0 (
    echo [INFO] Menjalankan Backend Server di background...
    start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
    timeout /t 3 /nobreak >nul
)

echo [INFO] Menjalankan Voicebox Web UI...
cd /d "%ROOT_DIR%web"
"%BUN_CMD%" run dev
