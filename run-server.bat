@echo off
title Voicebox - Backend Server (Port 17493)

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

set "PYTHON_EXE=%ROOT_DIR%backend\venv\Scripts\python.exe"

if not exist "%PYTHON_EXE%" (
    echo [ERROR] Virtual Environment (%PYTHON_EXE%) tidak ditemukan!
    echo Silakan jalankan setup.bat terlebih dahulu untuk menyiapkan Python 3.12 dan dependensinya.
    echo.
    pause
    exit /b 1
)

echo ======================================================================
echo          VOICEBOX FASTAPI SERVER (http://127.0.0.1:17493)
echo ======================================================================
echo [INFO] Python: %PYTHON_EXE%
echo [INFO] Server siap menerima koneksi dari Tauri desktop, Web, dan MCP.
echo [INFO] Tekan Ctrl+C untuk mematikan server.
echo.

"%PYTHON_EXE%" -m uvicorn backend.main:app --reload --port 17493
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Server berhenti dengan kode error: %ERRORLEVEL%
    pause
)
