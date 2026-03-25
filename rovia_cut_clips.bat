@echo off
REM ROVIA Clip Cutter -- Windows
REM Cuts highlight clips from a ROVIA dry-run manifest CSV.
REM
REM Usage:
REM   rovia_cut_clips.bat <manifest_csv>
REM
REM Example:
REM   rovia_cut_clips.bat "Rovia_Clips\rovia_manifest_20250325T214500Z.csv"
REM
REM Requires: ffmpeg in PATH
REM   winget install ffmpeg   OR   https://ffmpeg.org/download.html
REM Video stream is copied (no re-encode). Audio re-encoded to AAC for MP4 compatibility.

set CSV=%~1

if "%CSV%"=="" (
    echo ERROR: No manifest file specified.
    echo Usage: rovia_cut_clips.bat ^<manifest_csv^>
    pause
    exit /b 1
)

if not exist "%CSV%" (
    echo ERROR: File not found: %CSV%
    pause
    exit /b 1
)

where ffmpeg >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ffmpeg not found. Install it first:
    echo   winget install ffmpeg
    echo   OR download from https://ffmpeg.org/download.html and add to PATH
    pause
    exit /b 1
)

echo ============================================================
echo ROVIA Clip Cutter
echo Manifest: %CSV%
echo ============================================================

REM Skip header row and process each clip
set SKIP=1
for /f "usebackq tokens=1,2,3,4,5 delims=," %%a in ("%CSV%") do (
    if defined SKIP (
        set SKIP=
    ) else (
        echo.
        echo Cutting: %%~nxa
        echo   %%bs -^> %%cs  =^>  %%~nxe
        ffmpeg -y -i "%%a" -ss %%b -to %%c -c:v copy -c:a aac "%%e" -loglevel error
        echo   Done.
    )
)

echo.
echo ============================================================
echo Clip cutting complete.
echo ============================================================
pause
