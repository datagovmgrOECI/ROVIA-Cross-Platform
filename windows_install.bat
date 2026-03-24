@echo off
REM ROVIA Installation Script for Windows
REM This script downloads ROVIA, sets up the conda environment, and applies Windows fixes

echo ============================================================
echo ROVIA Windows Installation Script
echo ============================================================
echo.

REM Check if git is available
where git >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git not found!
    echo Please install Git for Windows from:
    echo https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

REM Check if conda is available
where conda >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Conda/Miniconda not found!
    echo Please install Miniconda first from:
    echo https://docs.conda.io/en/latest/miniconda.html
    echo.
    echo After installation, run this script again from Anaconda Prompt
    pause
    exit /b 1
)

echo Step 1: Cloning ROVIA repository from GitHub...
if exist ROVIA (
    echo ROVIA directory already exists. Skipping clone.
) else (
    git clone https://github.com/oeci/ROVIA.git
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to clone repository
        pause
        exit /b 1
    )
)

cd ROVIA
echo Changed to ROVIA directory

echo.
echo Step 2: Creating conda environment 'rovia' with Python 3.9...
call conda create -n rovia python=3.9 -y
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create conda environment
    pause
    exit /b 1
)

echo.
echo Step 3: Activating conda environment...
call conda activate rovia
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to activate environment
    pause
    exit /b 1
)

echo.
echo Step 4: Installing TensorFlow 2.15.0...
pip install tensorflow==2.15.0
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install TensorFlow
    pause
    exit /b 1
)

echo.
echo Step 5: Installing moviepy (specific version for compatibility)...
pip install moviepy==1.0.3
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install moviepy
    pause
    exit /b 1
)

echo.
echo Step 6: Installing h5py (specific version for large model files)...
pip install h5py==3.10.0
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install h5py
    pause
    exit /b 1
)

echo.
echo Step 7: Installing numpy (compatible with TensorFlow 2.15)...
pip install numpy==1.26.4
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install numpy
    pause
    exit /b 1
)

echo.
echo Step 7: Applying moviepy timecode fix...
python -c "import moviepy; print(moviepy.__file__)" > temp_path.txt
set /p MOVIEPY_PATH=<temp_path.txt
del temp_path.txt

REM Extract directory path from __init__.py path
for %%i in ("%MOVIEPY_PATH%") do set MOVIEPY_DIR=%%~dpi

echo Patching moviepy tools.py...
python -c "import os; path = r'%MOVIEPY_DIR%tools.py'; content = open(path, 'r', encoding='utf-8').read(); content = content.replace(\"if is_string(time):     \n        time = [float(f.replace(',', '.')) for f in time.split(':')]\", \"if is_string(time):\n        # Replace semicolons with colons to handle drop-frame timecode (e.g., 00:01:39;28)\n        time = time.replace(';', ':')\n        time = [float(f.replace(',', '.')) for f in time.split(':')]\"); open(path, 'w', encoding='utf-8').write(content); print('Moviepy patched successfully')"

if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Could not automatically patch moviepy. You may need to apply the fix manually.
)

echo.
echo Step 8: Installing opencv-python...
pip install opencv-python
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to install opencv-python
    pause
    exit /b 1
)

echo.
echo Step 9: Applying Windows path fix to rovia.py...
python -c "import os; path = 'rovia.py'; content = open(path, 'r', encoding='utf-8').read(); content = content.replace(\"filename = path.split('/')[-1].split('.')[0]\", \"# Use os.path.basename to handle both Windows and Unix paths\n        filename = os.path.splitext(os.path.basename(path))[0]\"); open(path, 'w', encoding='utf-8').write(content); print('Windows path fix applied to rovia.py')"

if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Could not automatically apply Windows path fix to rovia.py
)

echo.
echo Step 10: Creating optimized rovia_v2.py...
if not exist rovia_v2.py (
    echo Downloading rovia_v2.py...
    echo NOTE: rovia_v2.py must be manually placed in this directory
    echo You can get it from the installation package or create it separately
) else (
    echo rovia_v2.py already exists
)

echo.
echo ============================================================
echo Installation Complete!
echo ============================================================
echo.
echo Installed Versions:
echo - Python: 3.9
echo - TensorFlow: 2.15.0 (CPU-only)
echo - Keras: 2.15.0
echo - numpy: 1.26.4
echo - moviepy: 1.0.3
echo - h5py: 3.10.0
echo - opencv-python: latest
echo.
echo NEXT STEPS:
echo 1. Download the model file from Google Drive:
echo    https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view
echo.
echo 2. Place the model file (grama.hdf5) in the ROVIA directory
echo.
echo 3. (Optional) Copy rovia_v2.py to this directory for optimized performance
echo    rovia_v2.py offers 30-100%% faster processing with format options
echo.
echo 4. To use ROVIA, always activate the environment first:
echo    conda activate rovia
echo.
echo 5. Navigate to ROVIA directory:
echo    cd ROVIA
echo.
echo 6. Run ROVIA v1.0 (Windows-patched):
echo    python rovia.py -f "path\to\videos\" -m "./grama.hdf5"
echo.
echo 7. Run ROVIA v2.0 (optimized, if available):
echo    python rovia_v2.py -f "path\to\videos\" -m "./grama.hdf5"
echo.
echo 8. For native ProRes MOV output (v2.0):
echo    python rovia_v2.py -f "path\to\videos\" -m "./grama.hdf5" -o native
echo.
echo ============================================================
pause
