@echo off
setlocal enabledelayedexpansion
title Voicebox - AI Voice Studio Launcher

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

if exist "%USERPROFILE%\.bun\bin\bun.exe" (
    set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

:MENU
cls
echo ======================================================================
echo                 VOICEBOX - AI VOICE STUDIO LAUNCHER
echo ======================================================================
echo.
echo   [1] Jalankan Voicebox Desktop  (Backend Server + Tauri App)
echo   [2] Jalankan Backend Saja      (FastAPI Server di port 17493)
echo   [3] Jalankan Web UI Saja       (Browser Mode via Vite)
echo   [4] Setup Dependensi Lengkap   (Install Bun, Python 3.12, PyTorch)
echo   [5] Cek Status Service dan Port (Health Check :17493)
echo   [0] Keluar
echo.
echo ======================================================================
set /p "CHOICE=Pilih menu [0-5]: "

if "%CHOICE%"=="1" goto START_DESKTOP
if "%CHOICE%"=="2" goto START_SERVER
if "%CHOICE%"=="3" goto START_WEB
if "%CHOICE%"=="4" goto SETUP_ENV
if "%CHOICE%"=="5" goto CHECK_STATUS
if "%CHOICE%"=="0" goto EXIT_APP

echo Pilihan tidak valid, silakan coba lagi.
timeout /t 2 >nul
goto MENU

:START_DESKTOP
cls
echo [INFO] Memeriksa environment sebelum menjalankan Voicebox Desktop...
call :CHECK_VENV_EXISTS
if errorlevel 1 goto MENU
call :CHECK_BUN_EXISTS
if errorlevel 1 goto MENU

echo.
echo [1/2] Memeriksa status Backend Server (port 17493)...
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% EQU 0 (
    echo [OK] Backend server sudah berjalan di http://127.0.0.1:17493.
) else (
    echo [INFO] Menjalankan Backend Server di jendela terpisah...
    start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
    echo [INFO] Menunggu backend siap (3 detik)...
    timeout /t 3 /nobreak >nul
)

echo.
echo [2/2] Menyiapkan placeholder dev sidecar...
node scripts/setup-dev-sidecar.js

echo.
echo [INFO] Menjalankan Tauri Desktop App...
cd /d "%ROOT_DIR%tauri"
bun run tauri dev

echo.
echo Desktop app telah ditutup.
pause
goto MENU

:START_SERVER
cls
echo ======================================================================
echo                 STARTING VOICEBOX BACKEND SERVER
echo ======================================================================
echo.
call :CHECK_VENV_EXISTS
if errorlevel 1 (
    pause
    goto MENU
)

set "PYTHON_EXE=%ROOT_DIR%backend\venv\Scripts\python.exe"

echo [INFO] Menggunakan Python: %PYTHON_EXE%
echo [INFO] Endpoint FastAPI: http://localhost:17493
echo [INFO] Tekan Ctrl+C untuk menghentikan server.
echo.

"%PYTHON_EXE%" -m uvicorn backend.main:app --reload --port 17493
pause
goto MENU

:START_WEB
cls
echo ======================================================================
echo                 STARTING VOICEBOX WEB UI
echo ======================================================================
echo.
call :CHECK_BUN_EXISTS
if errorlevel 1 (
    pause
    goto MENU
)

echo [INFO] Memeriksa apakah Backend Server sudah aktif...
powershell -NoProfile -Command "try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Backend server belum aktif di port 17493!
    echo [INFO] Menjalankan backend server otomatis di jendela terpisah...
    start "Voicebox Backend Server (:17493)" cmd /k "cd /d "%ROOT_DIR%" && call run-server.bat"
    timeout /t 3 /nobreak >nul
)

echo.
echo [INFO] Menjalankan Vite Web Server...
cd /d "%ROOT_DIR%web"
bun run dev
pause
goto MENU

:SETUP_ENV
cls
call "%ROOT_DIR%setup.bat"
pause
goto MENU

:CHECK_STATUS
cls
echo ======================================================================
echo                      VOICEBOX HEALTH CHECK
echo ======================================================================
echo.
echo [1] Memeriksa Port 17493 (Backend)...
powershell -NoProfile -Command "try { $res = Invoke-RestMethod -Uri 'http://127.0.0.1:17493/health' -TimeoutSec 2; Write-Host ' [STATUS: ONLINE]' -ForegroundColor Green; Write-Host ($res | ConvertTo-Json -Depth 2) } catch { Write-Host ' [STATUS: OFFLINE] Backend tidak merespon di http://127.0.0.1:17493' -ForegroundColor Yellow }"

echo.
echo [2] Memeriksa Python Virtual Environment (backend\venv)...
if exist "%ROOT_DIR%backend\venv\Scripts\python.exe" (
    "%ROOT_DIR%backend\venv\Scripts\python.exe" --version
) else (
    echo [WARNING] backend\venv belum dibuat. Silakan pilih menu [4] Setup.
)

echo.
echo [3] Memeriksa Bun Runtime...
where bun >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    bun --version
) else (
    echo [WARNING] Bun tidak ditemukan di PATH.
)

echo.
echo [4] Memeriksa Placeholder Dev Sidecar...
if exist "%ROOT_DIR%tauri\src-tauri\binaries\voicebox-server-*.exe" (
    echo [OK] Placeholder binaries ditemukan.
) else (
    echo [WARNING] Placeholder belum dibuat. Menjalankan setup sidecar sekarang...
    node "%ROOT_DIR%scripts\setup-dev-sidecar.js"
)

echo.
pause
goto MENU

:CHECK_VENV_EXISTS
if not exist "%ROOT_DIR%backend\venv\Scripts\python.exe" (
    echo.
    echo [PERINGATAN] Virtual Environment Python (backend\venv) belum ditemukan!
    echo Anda harus melakukan setup terlebih dahulu melalui menu [4].
    set /p "RUN_SETUP=Apakah ingin menjalankan setup sekarang? (Y/N): "
    if /i "!RUN_SETUP!"=="Y" (
        call "%ROOT_DIR%setup.bat"
        exit /b 0
    )
    exit /b 1
)
exit /b 0

:CHECK_BUN_EXISTS
where bun >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    if exist "%USERPROFILE%\.bun\bin\bun.exe" (
        set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
        exit /b 0
    )
    echo.
    echo [PERINGATAN] Bun runtime belum terinstall!
    echo Voicebox membutuhkan Bun untuk antarmuka pengguna.
    set /p "INSTALL_BUN=Apakah Anda ingin menginstal Bun otomatis? (Y/N): "
    if /i "!INSTALL_BUN!"=="Y" (
        powershell -NoProfile -Command "irm bun.sh/install.ps1 | iex"
        set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
        exit /b 0
    )
    exit /b 1
)
exit /b 0

:EXIT_APP
echo Sampai jumpa!
exit /b 0
