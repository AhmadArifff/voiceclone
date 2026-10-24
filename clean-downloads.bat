@echo off
setlocal enabledelayedexpansion
title Voicebox - Pembersih Folder Downloads

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"
set "DOWNLOADS_DIR=%ROOT_DIR%downloads"

:CLEAN_MENU
cls
echo ======================================================================
echo             🧹 VOICEBOX - PEMBERSIH FOLDER DOWNLOADS
echo ======================================================================
echo Folder target: %DOWNLOADS_DIR%
echo.
echo Menghitung ukuran file...
powershell -NoProfile -Command ^
    "$pip = Get-ChildItem -Path '%DOWNLOADS_DIR%\pip_cache' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum;" ^
    "$models = Get-ChildItem -Path '%DOWNLOADS_DIR%\models' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum;" ^
    "$torch = Get-ChildItem -Path '%DOWNLOADS_DIR%\torch' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum;" ^
    "$total = Get-ChildItem -Path '%DOWNLOADS_DIR%' -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne '.gitkeep' } | Measure-Object -Property Length -Sum;" ^
    "function ToMB($b) { if ($b) { return [math]::Round($b / 1MB, 2) } else { return 0 } };" ^
    "Write-Host ('  1. Pip Cache (File .whl)      : ' + (ToMB $pip.Sum) + ' MB');" ^
    "Write-Host ('  2. AI Models (Hugging Face)   : ' + (ToMB $models.Sum) + ' MB');" ^
    "Write-Host ('  3. Torch Hub Models           : ' + (ToMB $torch.Sum) + ' MB');" ^
    "Write-Host '  --------------------------------------------------';" ^
    "Write-Host ('  Total Ukuran Downloads        : ' + (ToMB $total.Sum) + ' MB');"

echo.
echo ======================================================================
echo Pilihan Pembersihan:
echo   [1] Hapus Cache Pip Saja       (Aman: hanya file installer .whl sementara)
echo   [2] Hapus Cache Model AI Saja  (Model TTS/Whisper akan diunduh ulang saat dipakai)
echo   [3] Hapus SEMUA Isi Downloads  (Bersihkan seluruh folder downloads)
echo   [4] Buka Folder Downloads di File Explorer
echo   [0] Kembali
echo ======================================================================
set /p "CHOICE=Pilih opsi [0-4]: "

if "%CHOICE%"=="1" goto CLEAN_PIP
if "%CHOICE%"=="2" goto CLEAN_MODELS
if "%CHOICE%"=="3" goto CLEAN_ALL
if "%CHOICE%"=="4" goto OPEN_EXPLORER
if "%CHOICE%"=="0" goto EXIT_SCRIPT

echo Pilihan tidak valid.
timeout /t 2 >nul
goto CLEAN_MENU

:CLEAN_PIP
echo.
echo Menghapus cache pip di %DOWNLOADS_DIR%\pip_cache ...
if exist "%DOWNLOADS_DIR%\pip_cache" (
    rd /s /q "%DOWNLOADS_DIR%\pip_cache"
    mkdir "%DOWNLOADS_DIR%\pip_cache"
    echo [OK] Cache pip berhasil dibersihkan!
) else (
    echo [INFO] Folder pip_cache sudah kosong.
)
pause
goto CLEAN_MENU

:CLEAN_MODELS
echo.
echo Menghapus model AI di %DOWNLOADS_DIR%\models dan %DOWNLOADS_DIR%\huggingface ...
if exist "%DOWNLOADS_DIR%\models" rd /s /q "%DOWNLOADS_DIR%\models"
if exist "%DOWNLOADS_DIR%\huggingface" rd /s /q "%DOWNLOADS_DIR%\huggingface"
if exist "%DOWNLOADS_DIR%\torch" rd /s /q "%DOWNLOADS_DIR%\torch"
mkdir "%DOWNLOADS_DIR%\models"
echo [OK] Cache model AI berhasil dibersihkan!
pause
goto CLEAN_MENU

:CLEAN_ALL
echo.
set /p "CONFIRM=Yakin ingin menghapus SEMUA isi folder downloads? (Y/N): "
if /i "!CONFIRM!"=="Y" (
    powershell -NoProfile -Command "Get-ChildItem -Path '%DOWNLOADS_DIR%' -Exclude '.gitkeep' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    mkdir "%DOWNLOADS_DIR%\pip_cache" >nul 2>&1
    mkdir "%DOWNLOADS_DIR%\models" >nul 2>&1
    mkdir "%DOWNLOADS_DIR%\torch" >nul 2>&1
    echo [OK] Seluruh isi folder downloads telah dibersihkan!
) else (
    echo [BATAL] Pembersihan dibatalkan.
)
pause
goto CLEAN_MENU

:OPEN_EXPLORER
start explorer.exe "%DOWNLOADS_DIR%"
goto CLEAN_MENU

:EXIT_SCRIPT
exit /b 0
