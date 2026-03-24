# ROVIA Windows Installation Guide

Complete installation guide for running ROVIA v1.0 and v2.0 on Windows.

## Prerequisites

### 1. Install Git for Windows

Download and install Git:
- **Download:** https://git-scm.com/download/win
- Run the installer with default options

### 2. Install Miniconda

Download and install Miniconda for Windows:
- **Download:** https://docs.conda.io/en/latest/miniconda.html
- Choose: "Miniconda3 Windows 64-bit"
- Run the installer
- **Important:** When asked, check "Add Miniconda3 to my PATH environment variable"

### 3. Download ROVIA Model File

Download the pre-trained model from Google Drive:
- **Link:** https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view
- **File:** grama.hdf5 (~6.6 GB)
- Save it to your ROVIA directory (e.g., `Documents\ROVIA\ROVIA\`)

## Automated Installation

### Option 1: Run Installation Script (Recommended)

1. Download `windows_install.bat` to a folder (e.g., Documents)
2. Open **Anaconda Prompt** (search for it in Windows Start menu)
3. Navigate to where you saved the script:
   ```bash
   cd Documents
   ```
4. Run the installation script:
   ```bash
   windows_install.bat
   ```
5. Wait for installation to complete (5-10 minutes)

The script will:
- Clone the ROVIA repository from GitHub
- Create a conda environment named `rovia` with Python 3.9
- Install TensorFlow 2.15.0 and all required dependencies
- Apply moviepy timecode fix for NTSC drop-frame support
- Apply Windows path fix to rovia.py
- Set up the environment for both rovia.py and rovia_v2.py

## Manual Installation

If the automated script fails, follow these steps:

### Step 1: Clone ROVIA Repository

```bash
git clone https://github.com/oeci/ROVIA.git
cd ROVIA
```

### Step 2: Create Conda Environment

```bash
conda create -n rovia python=3.9 -y
conda activate rovia
```

### Step 2: Install TensorFlow and Keras

```bash
pip install tensorflow==2.15.0
```

This will automatically install Keras 2.15.0 as a dependency.

### Step 3: Install moviepy

**Critical:** Must use version 1.0.3 for compatibility:

```bash
pip install moviepy==1.0.3
```

### Step 4: Install h5py

**Critical:** Version 3.10.0 is required to handle the large 6.6GB model file:

```bash
pip install h5py==3.10.0
```

### Step 5: Install numpy

**Critical:** Version 1.26.4 is required for TensorFlow 2.15 compatibility:

```bash
pip install numpy==1.26.4
```

### Step 6: Install OpenCV

```bash
pip install opencv-python
```

### Step 7: Apply Moviepy Timecode Fix

This fix is needed to handle NTSC drop-frame timecodes in video metadata.

1. Find moviepy installation path:
   ```bash
   python -c "import moviepy; import os; print(os.path.dirname(moviepy.__file__))"
   ```

2. Open `tools.py` in that directory with a text editor

3. Find this code (around line 94-95):
   ```python
   if is_string(time):
       time = [float(f.replace(',', '.')) for f in time.split(':')]
   ```

4. Replace with:
   ```python
   if is_string(time):
       # Replace semicolons with colons to handle drop-frame timecode (e.g., 00:01:39;28)
       time = time.replace(';', ':')
       time = [float(f.replace(',', '.')) for f in time.split(':')]
   ```

5. Save the file

### Step 7: Apply Windows Path Fix to rovia.py

1. Open `rovia.py` in a text editor

2. Find line 236:
   ```python
   filename = path.split('/')[-1].split('.')[0]
   ```

3. Replace with:
   ```python
   # Use os.path.basename to handle both Windows and Unix paths
   filename = os.path.splitext(os.path.basename(path))[0]
   ```

4. Save the file

## System Requirements

### Minimum Requirements
- **RAM:** 16 GB
- **Storage:** 10 GB free space (for model and dependencies)
- **OS:** Windows 10 or later
- **Python:** 3.9

### Recommended Requirements
- **RAM:** 32 GB (for processing large videos without memory issues)
- **Storage:** 50+ GB for video processing
- **GPU:** NVIDIA GPU with CUDA support (optional, for faster processing)

### GPU Support (Optional)

ROVIA v2.0 includes GPU support, but requires additional setup:

**Requirements:**
- NVIDIA GPU (RTX series recommended)
- CUDA 11.8
- cuDNN 8.6

**Note:** TensorFlow 2.15 with your current Python 3.9 environment only supports CUDA 11.8. If you have CUDA 12.x installed, you would need to:
1. Either install CUDA 11.8 alongside your existing CUDA, or
2. Upgrade to Python 3.10+ and TensorFlow 2.16+

For most users, CPU-only mode is sufficient and v2.0 provides significant speedups through other optimizations.

## Usage

### Always Activate Environment First

Before running ROVIA, activate the conda environment:

```bash
conda activate rovia
```

You should see `(rovia)` at the beginning of your command prompt.

### Running ROVIA v1.0

Basic usage:
```bash
python rovia.py -f "D:\EX2301\Video\" -m "./grama.hdf5"
```

With verbose output:
```bash
python rovia.py -f "D:\EX2301\Video\" -m "./grama.hdf5" -v 1
```

### Running ROVIA v2.0 (Optimized)

**Default (H.264 MP4 output):**
```bash
python rovia_v2.py -f "D:\EX2301\Video\" -m "./grama.hdf5"
```

**Native ProRes MOV output (maintains original quality and format):**
```bash
python rovia_v2.py -f "D:\EX2301\Video\" -m "./grama.hdf5" -o native
```

**With verbose output:**
```bash
python rovia_v2.py -f "D:\EX2301\Video\" -m "./grama.hdf5" -v 1 -o native
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-f` / `--folder` | **Required:** Path to folder containing videos | None |
| `-m` / `--model` | Path to model file | `./grama.hdf5` |
| `-v` / `--verbose` | Verbosity level (0 or 1) | 1 |
| `-o` / `--output` | Output format: `mp4` or `native` (v2.0 only) | `mp4` |

### Output Format Comparison (v2.0)

| Format | File Size | Quality | Encoding Speed | Use Case |
|--------|-----------|---------|----------------|----------|
| **mp4** (H.264) | Small (~10-50 MB/min) | Very Good | Fast | Quick review, sharing, web upload |
| **native** (ProRes MOV) | Large (~1-2 GB/min) | Lossless | Slower | Professional editing, archival, maximum quality |

## Performance Comparison

### ROVIA v1.0 vs v2.0

**v2.0 Optimizations:**
- 3x larger batch size for predictions (450 vs 150 frames)
- Persistent process pool across all videos
- Pre-allocated memory arrays
- Vectorized operations
- GPU support (if available)
- Optimized video encoding

**Expected Speedup:**
- Single video: 30-50% faster
- Multiple videos: 50-100% faster
- With GPU: 2-5x faster overall

## Output

Highlight clips are saved in the `Rovia_Clips` folder in the same directory as the script.

**Output file naming:**
```
EX2301_VID_20230415T152320Z_ROVHD_HL.mp4
                                    ^^
                                    Highlight suffix
```

## Troubleshooting

### "conda: command not found"

**Solution:** Use **Anaconda Prompt** instead of regular Command Prompt or PowerShell.

Find it: Start Menu → Search "Anaconda Prompt"

### "No module named 'moviepy.editor'"

**Solution:** Reinstall moviepy 1.0.3:
```bash
pip uninstall moviepy -y
pip install moviepy==1.0.3
```

### "Could not allocate bytes object" / Memory Error

**Possible causes:**
1. Insufficient RAM (need 16GB minimum, 32GB recommended)
2. h5py version issue

**Solution:**
```bash
pip install h5py==3.10.0
```

### "AttributeError: _ARRAY_API not found" / numpy Error

**Solution:** Ensure numpy version is correct:
```bash
pip install "numpy>=1.23.5,<2.0"
```

### "MoviePy error: failed to read the duration"

**Cause:** Moviepy can't parse drop-frame timecodes (semicolons in metadata)

**Solution:** Apply the moviepy timecode fix (Step 6 in Manual Installation)

### "OSError: [Errno 22] Invalid argument" / Path Error

**Cause:** Path handling issue on Windows

**Solution:** Ensure rovia.py has the Windows path fix applied (Step 7 in Manual Installation)

### Videos Process Slowly

**Tips to improve speed:**
1. Use ROVIA v2.0 instead of v1.0
2. Close other applications to free up RAM
3. Process shorter videos or split large videos
4. For maximum speed: Set up GPU support (advanced)

### GPU Not Detected

**Check GPU availability:**
```bash
python -c "import tensorflow as tf; print('GPUs:', tf.config.list_physical_devices('GPU'))"
```

**If empty:**
- TensorFlow 2.15 requires CUDA 11.8 (not CUDA 12.x)
- CPU-only mode still provides good performance with v2.0 optimizations

## Files Overview

| File | Description |
|------|-------------|
| `rovia.py` | Original ROVIA script |
| `rovia_v2.py` | Optimized version with GPU support and format options |
| `grama.hdf5` | Pre-trained deep learning model (~6.6 GB) |
| `requirements.txt` | Python package dependencies |
| `UserGuide.pdf` | Original user guide |
| `windows_install.bat` | Automated installation script |
| `windows_install.md` | This file |

## Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Review the `UserGuide.pdf` included with ROVIA
3. Verify all dependencies are correctly installed:
   ```bash
   pip list | findstr "tensorflow keras numpy opencv moviepy h5py"
   ```

## Version History

### ROVIA v2.0 Improvements
- 30-100% faster processing
- GPU acceleration support
- Native ProRes MOV output option
- Persistent process pool
- Optimized batch processing
- Better memory management
- Windows path compatibility

### Patches Applied
- Moviepy timecode parsing fix (semicolon handling)
- Windows path handling fix
- h5py compatibility fix
- numpy version compatibility

## License

ROVIA is licensed under the Apache License, Version 2.0

Copyright 2023 Ocean Exploration Cooperative Institute (OECI)

## Credits

**Original ROVIA:**
- Ocean Exploration Cooperative Institute (OECI)
- NOAA Ocean Exploration

**Windows Optimizations & v2.0:**
- Performance optimizations
- Windows compatibility fixes
- GPU support integration
- Format options
