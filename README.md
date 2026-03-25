<img width="174" alt="image" src="https://github.com/oeci/ROVIA/assets/132848329/16094bf7-4122-4cf8-a676-7459abe83093">

# ROVIA: Automated Deep-Sea Video Highlight Generator

ROVIA uses deep neural networks to automatically generate highlights from deep-sea ROV video footage. It is a field-deployable, portable tool designed for ocean exploration.

This fork adds **Windows 64-bit support**, a **Linux installer**, and a **dry-run mode** for previewing highlights before encoding.

> Original project: [oeci/ROVIA](https://github.com/oeci/ROVIA)
> Supported by NOAA Ocean Exploration Cooperative Institute (OECI)

---

## Requirements

- Python 3.9
- 16 GB RAM minimum (32 GB recommended)
- 10 GB free storage + ~7 GB for the model file
- NVIDIA GPU optional (CUDA 11.8 for GPU acceleration)

---

## Installation

### Windows
See [windows_install.md](windows_install.md) for full instructions, or run the automated installer:
```bat
windows_install.bat
```

### Linux
See [linux_install.md](linux_install.md) for full instructions, or run the automated installer:
```bash
bash linux_install.sh          # CPU only
bash linux_install.sh --gpu    # With NVIDIA GPU support
```

---

## Download the Model File

The trained model (~6.6 GB) must be downloaded separately:

**Google Drive:** https://drive.google.com/file/d/1ZOBWlAxCVILzxY2gexwV80Bb-uaAgYqy/view

Place `grama.hdf5` in the same directory as `rovia_v2.py`.

---

## Usage

Always activate the conda environment first:
```bash
conda activate rovia
```

### Basic — generate highlight clips
```bash
python rovia_v2.py -f "/path/to/videos/" -m "./grama.hdf5"
```

### Dry run — preview highlights without encoding video
```bash
python rovia_v2.py -f "/path/to/videos/" -m "./grama.hdf5" -d
```
Analyses all videos using the neural network and writes a text report to `Rovia_Clips/rovia_highlights_report.txt` showing what clips would be generated — source file, start/end times, duration, and output filename. No video files are written. Useful for quickly scanning a large batch before committing to a long encode job.

### All options
```
-f, --folder     Required: Folder containing video files (.mp4 or .mov)
-m, --model      Optional: Path to model file (default: ./grama.hdf5)
-v, --verbose    Optional: Verbosity level 0 or 1 (default: 1)
-o, --output     Optional: Output format — mp4 (default) or native (ProRes MOV)
-d, --dry-run    Optional: Report highlights only, do not encode video files
```

### Examples
```bash
# Standard MP4 output
python rovia_v2.py -f "./video/" -m "./grama.hdf5" -v 1

# ProRes MOV output (lossless quality)
python rovia_v2.py -f "./video/" -m "./grama.hdf5" -o native

# Dry run — text report only, no encoding
python rovia_v2.py -f "./video/" -m "./grama.hdf5" -d

# Dry run on Windows
python rovia_v2.py -f "C:\Videos\ROV_Dive\" -m "./grama.hdf5" -d
```

Output clips are saved to `./Rovia_Clips/` with `_HL` appended to the filename.

---

## Filename Format

ROVIA uses the video filename to timestamp output clips. Supported formats:

| Format | Example |
|--------|---------|
| `YYYYMMDDTHHmmssZ` | `EX2301_VID_20230415T152320Z_ROVHD.mp4` |
| `YYYYMMDD_HHmmss` | `NA171_MORPH_002_20250510_192524.mp4` |

Files without a recognisable timestamp still process correctly — output clips use the original filename.

---

## Testing on Linux via Docker Desktop (Windows)

If you are on Windows and want to test the Linux version using Docker Desktop:

```powershell
# Build the test image (one time)
docker build -f "Dockerfile.linux-test" -t rovia-linux-test .

# Run with your model and video files mounted
docker run -it --rm -v "C:\path\to\grama.hdf5:/rovia/grama.hdf5" -v "C:\path\to\videos:/rovia/video" -v "C:\path\to\output:/rovia/Rovia_Clips" rovia-linux-test
```

Inside the container:
```bash
conda activate rovia
python rovia_v2.py -f "./video/" -m "./grama.hdf5" -d
```

See [linux_install.md](linux_install.md) for full Docker and native Linux instructions.

---

## Acknowledgements

We thank NOAA Ocean Exploration, Ocean Exploration Trust, and Schmidt Ocean Institute for making ROV dive video publicly available. This project was generously supported by the NOAA Ocean Exploration Cooperative Institute (OECI).
