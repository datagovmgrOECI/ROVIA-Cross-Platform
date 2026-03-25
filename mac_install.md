# ROVIA Mac Installation Guide

Supports Intel Macs (x86_64) and Apple Silicon (M1/M2/M3, arm64).

## Requirements

- macOS 12 (Monterey) or later recommended
- 16 GB RAM minimum (32 GB recommended)
- 10 GB free storage + ~7 GB for the model file
- Apple Silicon: Metal GPU acceleration is automatic
- Intel Mac: CPU-only mode

---

## Prerequisites

### 1. Install Homebrew (if not already installed)

Homebrew is needed to install FFmpeg for the cut scripts.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Apple Silicon users: after install, follow the prompt to add Homebrew to your PATH:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Install Miniforge

Miniforge is recommended (no Anaconda TOS required, works on both Intel and Apple Silicon).

**Apple Silicon:**
```bash
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
bash Miniforge3-MacOSX-arm64.sh
source ~/.zshrc
```

**Intel Mac:**
```bash
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
bash Miniforge3-MacOSX-x86_64.sh
source ~/.zshrc
```

### 3. Download the ROVIA Model File

Download the pre-trained model from Google Drive:
- **Link:** https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view
- **File:** grama.hdf5 (~6.6 GB)
- Place it in the same directory as `rovia_v2.py`

---

## Automated Installation

Run the installer script (auto-detects Intel vs Apple Silicon):

```bash
bash mac_install.sh
```

The script will:
- Create a conda environment named `rovia` with Python 3.9
- Install the correct TensorFlow for your architecture
- Install all required dependencies in the correct order
- Install FFmpeg via Homebrew (for cut scripts)
- Verify all imports

---

## Manual Installation

If the automated script fails, follow these steps:

### Step 1: Create Conda Environment

```bash
conda create -n rovia python=3.9 -y
conda activate rovia
```

### Step 2: Install numpy first

**Critical:** numpy must be installed before TensorFlow.

```bash
pip install numpy==1.26.4
```

### Step 3: Install TensorFlow

**Apple Silicon:**
```bash
pip install tensorflow-macos==2.15.0
pip install tensorflow-metal
```

**Intel Mac:**
```bash
pip install tensorflow==2.15.0
```

### Step 4: Install remaining packages

```bash
pip install moviepy==1.0.3
pip install h5py==3.10.0
pip install opencv-python
```

### Step 5: Re-pin numpy

TensorFlow may have upgraded numpy during install — force it back:

```bash
pip install numpy==1.26.4 --force-reinstall
```

### Step 6: Install FFmpeg (for cut scripts)

FFmpeg is **not required to run ROVIA** — moviepy bundles its own FFmpeg binary.
FFmpeg is required only to run `rovia_cut_clips.sh` after a dry run.

```bash
brew install ffmpeg
```

---

## Usage

Always activate the environment first:

```bash
conda activate rovia
```

### Generate highlight clips (MP4)

```bash
python rovia_v2.py -f "/path/to/videos/" -m "./grama.hdf5"
```

### Dry run — preview highlights without encoding

```bash
python rovia_v2.py -f "/path/to/videos/" -m "./grama.hdf5" -d
```

Writes a CSV manifest and text report to `./Rovia_Clips/`. No video files are encoded.

### Cut clips from a dry-run manifest

```bash
bash rovia_cut_clips.sh ./Rovia_Clips/rovia_manifest_TIMESTAMP.csv
```

### ProRes MOV output

```bash
python rovia_v2.py -f "/path/to/videos/" -m "./grama.hdf5" -o native
```

### All options

| Option | Description | Default |
|--------|-------------|---------|
| `-f` / `--folder` | **Required:** Folder containing video files | — |
| `-m` / `--model` | Path to model file | `./grama.hdf5` |
| `-v` / `--verbose` | Verbosity level 0 or 1 | 1 |
| `-o` / `--output` | Output format: `mp4` or `native` (ProRes MOV) | `mp4` |
| `-d` / `--dry-run` | Report highlights only, no encoding | off |

---

## Troubleshooting

### "conda: command not found"

Run `source ~/.zshrc` (or `~/.bashrc`) after installing Miniforge, then try again.

### "No module named 'tensorflow'"

Make sure the rovia environment is active:
```bash
conda activate rovia
python -c "import tensorflow; print(tensorflow.__version__)"
```

### "AttributeError: _ARRAY_API not found" (numpy error)

TensorFlow upgraded numpy during install. Fix with:
```bash
pip install numpy==1.26.4 --force-reinstall
```

### Apple Silicon: tensorflow-metal errors

If you see Metal plugin errors on startup, they are usually warnings and do not affect CPU operation. To suppress:
```bash
export TF_CPP_MIN_LOG_LEVEL=2
python rovia_v2.py ...
```

### Verify GPU (Apple Silicon)

```bash
python -c "import tensorflow as tf; print('Devices:', tf.config.list_physical_devices())"
```

You should see a `METAL` device listed alongside `CPU`.

### Intel Mac: GPU not available

Intel Macs use CPU-only TensorFlow. ROVIA v2.0 has significant CPU optimizations and will still perform well.

---

## License

ROVIA is licensed under the Apache License, Version 2.0
Copyright 2023 Ocean Exploration Cooperative Institute (OECI)
