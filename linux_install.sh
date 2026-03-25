#!/bin/bash
# ROVIA Installation Script for Linux
# Tested on Ubuntu 20.04+, Debian 11+
# Usage: bash linux_install.sh [--gpu]

set -e

echo "============================================================"
echo "ROVIA Linux Installation Script"
echo "============================================================"
echo ""

# Parse arguments
GPU_SUPPORT=0
for arg in "$@"; do
    if [ "$arg" = "--gpu" ]; then
        GPU_SUPPORT=1
    fi
done

# Check for conda
if ! command -v conda &> /dev/null; then
    echo "ERROR: Conda not found!"
    echo ""
    echo "Install Miniforge (recommended - no TOS required):"
    echo "  wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
    echo "  bash Miniforge3-Linux-x86_64.sh"
    echo "  source ~/.bashrc"
    echo ""
    echo "Or Miniconda (requires accepting Anaconda TOS):"
    echo "  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    echo "  bash Miniconda3-latest-Linux-x86_64.sh"
    echo "  source ~/.bashrc"
    echo "  conda tos accept"
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
if [ "$GPU_SUPPORT" -eq 1 ]; then
    echo "Step 4: Installing TensorFlow 2.15.0 with GPU support..."
    echo "NOTE: Requires NVIDIA drivers, CUDA 11.8, and cuDNN 8.6 already installed."
    echo "See linux_install.md for CUDA setup instructions."
    pip install tensorflow[and-cuda]==2.15.0
else
    echo "Step 4: Installing TensorFlow 2.15.0 (CPU-only)..."
    echo "Tip: Re-run with --gpu flag for GPU acceleration if you have an NVIDIA GPU."
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
echo "Step 9: Installing FFmpeg (required to run generated rovia_cut_clips.sh scripts)..."
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
if command -v apt-get &> /dev/null; then
    $SUDO apt-get install -y ffmpeg
elif command -v dnf &> /dev/null; then
    $SUDO dnf install -y ffmpeg
else
    echo "NOTE: Could not auto-install FFmpeg. Install it manually before running rovia_cut_clips.sh."
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
echo "  TensorFlow: 2.15.0"
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
echo "4. For ProRes MOV output:"
echo "   python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -o native"
echo ""
echo "============================================================"
