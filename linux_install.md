# ROVIA Linux Installation Guide

ROVIA v2.0 runs on Linux without any code patches. The Python scripts (`rovia.py`, `rovia_v2.py`) use cross-platform path handling and all dependencies have Linux builds.

---

## System Requirements

**Minimum:**
- OS: Ubuntu 20.04 LTS, Debian 11, or RHEL/Rocky 8+
- Python: 3.9 (via Miniconda recommended)
- RAM: 16 GB
- Storage: 10 GB free (plus ~7 GB for the model file)

**Recommended:**
- RAM: 32 GB
- Storage: 50+ GB
- GPU: NVIDIA with CUDA 11.8 (RTX series recommended)

---

## Automated Installation

### CPU-only (no GPU)
```bash
bash linux_install.sh
```

### With GPU support
```bash
bash linux_install.sh --gpu
```
> **Note:** GPU mode requires NVIDIA drivers + CUDA 11.8 + cuDNN 8.6 installed first.
> See [CUDA Setup](#optional-gpu-cuda-setup) below.

---

## Manual Installation

### 1. Install Miniconda (if not already installed)
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
```

### 2. Create and activate conda environment
```bash
conda create -n rovia python=3.9 -y
conda activate rovia
```

### 3. Install dependencies
```bash
pip install tensorflow==2.15.0
pip install moviepy==1.0.3
pip install h5py==3.10.0
pip install numpy==1.26.4
pip install opencv-python
```

### 4. Install system libraries (required for OpenCV)
```bash
sudo apt-get update
sudo apt-get install -y libgl1-mesa-glx libglib2.0-0 ffmpeg
```

---

## Optional: GPU / CUDA Setup

TensorFlow 2.15 requires **CUDA 11.8** and **cuDNN 8.6**.

### Ubuntu 22.04 — CUDA 11.8
```bash
# Add NVIDIA package repository
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# Install CUDA 11.8
sudo apt-get install -y cuda-toolkit-11-8

# Install cuDNN 8.6 (requires NVIDIA developer account)
# Download from: https://developer.nvidia.com/cudnn
# Then: sudo dpkg -i cudnn-local-repo-ubuntu2204-8.6.0.163_1.0-1_amd64.deb

# Add to PATH
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

Then install tensorflow with GPU:
```bash
conda activate rovia
pip install tensorflow[and-cuda]==2.15.0
```

Verify GPU is detected:
```bash
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

---

## Download the Model File

The trained model (`grama.hdf5`, ~6.6 GB) must be downloaded separately:

```bash
# Download from Google Drive (requires gdown)
pip install gdown
gdown "1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy"
```

Or download manually from:
https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view

Place `grama.hdf5` in the ROVIA directory (same folder as `rovia_v2.py`).

---

## Running ROVIA

Always activate the conda environment first:
```bash
conda activate rovia
```

### ROVIA v2.0 (recommended)
```bash
python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -v 1
```

### With ProRes MOV output (lossless quality)
```bash
python rovia_v2.py -f /path/to/videos/ -m ./grama.hdf5 -o native
```

### ROVIA v1.0
```bash
python rovia.py -f /path/to/videos/ -m ./grama.hdf5 -v 1
```

Output clips are saved to `./Rovia_Clips/` with `_HL` appended to the filename.

---

## Testing with Docker Desktop (Windows Host)

If you are on Windows and want to test the Linux version before deploying, use Docker Desktop:

### 1. Build the test image
```powershell
docker build -f Dockerfile.linux-test -t rovia-linux-test .
```

### 2. Run with mounted model and video files
```powershell
docker run -it --rm `
  -v "C:\Users\Deb Smith\Documents\ROVIA\ROVIA\grama.hdf5:/rovia/grama.hdf5" `
  -v "C:\path\to\your\videos:/rovia/video" `
  -v "C:\Users\Deb Smith\Desktop\rovia-output:/rovia/Rovia_Clips" `
  rovia-linux-test
```

### 3. Inside the container
```bash
conda activate rovia
python rovia_v2.py -f ./video/ -m ./grama.hdf5 -v 1
```

Highlight clips will appear in `C:\Users\Deb Smith\Desktop\rovia-output\` on your Windows desktop.

---

## Troubleshooting

### `libGL.so.1: cannot open shared object file`
```bash
sudo apt-get install libgl1-mesa-glx
```

### `libgthread-2.0.so.0: cannot open shared object file`
```bash
sudo apt-get install libglib2.0-0
```

### Memory allocation errors with large videos
Reduce chunk size or use a machine with more RAM. ROVIA processes videos in 600-frame chunks — each chunk is loaded into memory simultaneously.

### TensorFlow GPU not detected
1. Verify CUDA version: `nvcc --version` (should show 11.8)
2. Verify cuDNN is installed: `find /usr -name "libcudnn*" 2>/dev/null`
3. Check TF GPU list: `python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"`

### numpy compatibility errors
Ensure numpy 1.26.4 is installed — newer versions break TensorFlow 2.15:
```bash
pip install numpy==1.26.4 --force-reinstall
```

### h5py errors loading grama.hdf5
```bash
pip install h5py==3.10.0 --force-reinstall
```
