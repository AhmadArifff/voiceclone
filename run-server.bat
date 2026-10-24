@echo off
title Voicebox - Backend Server (Port 17493)

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

REM Konfigurasi folder model dan cache terpusat
set "DOWNLOADS_DIR=%ROOT_DIR%downloads"
if not exist "%DOWNLOADS_DIR%\models" mkdir "%DOWNLOADS_DIR%\models"
set "VOICEBOX_MODELS_DIR=%DOWNLOADS_DIR%\models"
set "HF_HOME=%DOWNLOADS_DIR%\huggingface"
set "HF_HUB_CACHE=%DOWNLOADS_DIR%\models"
set "TORCH_HOME=%DOWNLOADS_DIR%\torch"

set "PYTHON_EXE=%ROOT_DIR%backend\venv\Scripts\python.exe"

if exist "%PYTHON_EXE%" goto VENV_OK

echo [ERROR] Virtual Environment Python tidak ditemukan!
echo Path yang dicari: %PYTHON_EXE%
echo Silakan jalankan setup.bat terlebih dahulu untuk menyiapkan Python 3.12 dan dependensinya.
echo.
pause
exit /b 1

:VENV_OK
echo ======================================================================
echo          VOICEBOX FASTAPI SERVER (http://127.0.0.1:17493)
echo ======================================================================
echo [INFO] Python          : %PYTHON_EXE%
echo [INFO] Folder Model AI : %VOICEBOX_MODELS_DIR%
echo [INFO] Server siap menerima koneksi dari Web, Desktop, dan MCP.
echo [INFO] Tekan Ctrl+C untuk mematikan server.
echo.

"%PYTHON_EXE%" -m uvicorn backend.main:app --reload --reload-dir backend --reload-exclude "*venv*" --reload-exclude "*data*" --reload-exclude "*downloads*" --port 17493
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Server berhenti dengan kode error: %ERRORLEVEL%
    pause
)
