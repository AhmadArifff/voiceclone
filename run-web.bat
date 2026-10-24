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
if %ERRORLEVEL% EQU 0 goto BUN_OK

echo [ERROR] Bun tidak ditemukan di PATH!
echo Jalankan setup.bat terlebih dahulu untuk menginstal Bun.
pause
exit /b 1

:BUN_OK
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% EQU 0 goto SERVER_READY

echo [INFO] Menjalankan Backend Server di background...
start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
timeout /t 3 /nobreak >nul

:SERVER_READY
echo [INFO] Membuka web browser di http://localhost:5173 ...
start http://localhost:5173

echo [INFO] Menjalankan Voicebox Web UI...
cd /d "%ROOT_DIR%web"
"%BUN_CMD%" run dev
