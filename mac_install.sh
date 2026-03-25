#!/bin/bash
# ROVIA Installation Script for Mac
# Supports Intel (x86_64) and Apple Silicon (arm64)
# Usage: bash mac_install.sh

set -e

echo "============================================================"
echo "ROVIA Mac Installation Script"
echo "============================================================"
echo ""

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "Detected: Apple Silicon (arm64) — Metal GPU acceleration available"
else
    echo "Detected: Intel Mac (x86_64) — CPU mode"
fi
echo ""

# Check for conda
if ! command -v conda &> /dev/null; then
    echo "ERROR: Conda not found!"
    echo ""
    echo "Install Miniforge (recommended - no TOS required, works on Intel and Apple Silicon):"
    if [ "$ARCH" = "arm64" ]; then
        echo "  curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
        echo "  bash Miniforge3-MacOSX-arm64.sh"
    else
        echo "  curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
        echo "  bash Miniforge3-MacOSX-x86_64.sh"
    fi
    echo "  source ~/.zshrc   (or source ~/.bashrc if using bash)"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

echo "Step 1: Creating conda environment 'rovia' with Python 3.9..."
conda create -n rovia python=3.9 -y
echo "Environment created."

echo ""
echo "Step 2: Activating conda environment..."
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate rovia

echo ""
echo "Step 3: Installing numpy 1.26.4 first (must precede TensorFlow install)..."
pip install numpy==1.26.4

echo ""
if [ "$ARCH" = "arm64" ]; then
    echo "Step 4: Installing TensorFlow for Apple Silicon (tensorflow-macos 2.15.0 + tensorflow-metal)..."
    echo "Note: tensorflow-metal enables GPU acceleration via Apple Metal."
    pip install tensorflow-macos==2.15.0
    pip install tensorflow-metal
else
    echo "Step 4: Installing TensorFlow 2.15.0 (CPU-only, Intel Mac)..."
    pip install tensorflow==2.15.0
fi

echo ""
echo "Step 5: Installing moviepy 1.0.3..."
pip install moviepy==1.0.3

echo ""
echo "Step 6: Installing h5py 3.10.0 (required for large model files)..."
pip install h5py==3.10.0

echo ""
echo "Step 7: Installing OpenCV..."
pip install opencv-python

echo ""
echo "Step 8: Re-pinning numpy 1.26.4 (TF may have upgraded it)..."
pip install numpy==1.26.4 --force-reinstall

echo ""
echo "Step 9: Installing FFmpeg via Homebrew (required to run rovia_cut_clips.sh)..."
if command -v brew &> /dev/null; then
    brew install ffmpeg
else
    echo "NOTE: Homebrew not found. Install FFmpeg manually to use rovia_cut_clips.sh:"
    echo "  Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo "  Then: brew install ffmpeg"
fi

echo ""
echo "Step 10: Verifying installation..."
python -c "
import tensorflow as tf
import cv2
import numpy as np
import moviepy
import h5py
print('tensorflow:', tf.__version__)
print('opencv:', cv2.__version__)
print('numpy:', np.__version__)
print('h5py:', h5py.__version__)
print('All packages verified OK')
"

echo ""
echo "============================================================"
echo "Installation Complete!"
echo "============================================================"
echo ""
echo "Installed versions:"
echo "  Python:     3.9"
if [ "$ARCH" = "arm64" ]; then
    echo "  TensorFlow: 2.15.0 (tensorflow-macos + tensorflow-metal)"
else
    echo "  TensorFlow: 2.15.0"
fi
echo "  numpy:      1.26.4"
echo "  moviepy:    1.0.3"
echo "  h5py:       3.10.0"
echo "  opencv:     latest"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Download the model file from Google Drive:"
echo "   https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view"
echo "   Place grama.hdf5 in this directory."
echo ""
echo "2. Activate the environment before running:"
echo "   conda activate rovia"
echo ""
echo "3. Run ROVIA v2.0:"
echo "   python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -v 1"
echo ""
echo "4. Dry run (preview highlights without encoding):"
echo "   python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -d"
echo ""
echo "5. For ProRes MOV output:"
echo "   python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -o native"
echo ""
echo "============================================================"
