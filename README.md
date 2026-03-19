# PyTorch 2.9.1 Custom Build Environment

This Flox environment builds custom PyTorch 2.9.1 variants with **CUDA 12.9** support and targeted optimizations for specific GPU architectures and CPU instruction sets. It is an example environment created to complement [this guide](https://flox.dev/blog/gpu-optimized-pytorch-builds-made-easy-with-flox-and-nix/).

## Key Features

- **PyTorch Version**: 2.9.1 (latest stable)
- **CUDA Version**: 12.9 (`cudaPackages_12_9`)
- **GPU Support**: 8 SM architectures from Pascal (SM61) through Vera Rubin (SM120)
- **Platforms**: x86_64-linux, aarch64-linux, aarch64-darwin (Apple Silicon)
- **Custom MAGMA**: Per-SM static MAGMA libraries for each GPU architecture
- **Closure Stripping**: Removes build-time gcc/binutils references (~317 MiB saved per build)
- **Build Method**: Uses upstream nixpkgs PyTorch with overrides via a parametric builder

## Quick Start

```bash
# Enter the build environment
cd /home/daedalus/dev/builds/gpu-specific-pytorch-2.9.1
flox activate

# Build a specific variant
flox build pytorch-python313-cuda12_9-sm90-avx2

# The result will be in ./result-pytorch-python313-cuda12_9-sm90-avx2/
ls -lh result-pytorch-python313-cuda12_9-sm90-avx2/lib/python3.13/site-packages/torch/
```

## Available Variants

### GPU Builds (CUDA 12.9) — 15 packages

Each GPU build uses a custom per-SM static MAGMA library and cuBLAS for linear algebra. Most architectures offer both AVX2 (broad x86-64 compatibility) and AVX-512 (modern server CPUs) variants.

| GPU Architecture | Hardware | AVX2 Package | AVX-512 Package |
|------------------|----------|--------------|-----------------|
| SM120 (Vera Rubin) | R100 | `pytorch-python313-cuda12_9-sm120-avx2` | `pytorch-python313-cuda12_9-sm120-avx512` |
| SM100 (Blackwell) | B200, GB200 | `pytorch-python313-cuda12_9-sm100-avx2` | `pytorch-python313-cuda12_9-sm100-avx512` |
| SM90 (Hopper) | H100, H200, L40S | `pytorch-python313-cuda12_9-sm90-avx2` | `pytorch-python313-cuda12_9-sm90-avx512` |
| SM89 (Ada Lovelace) | L40, RTX 4090 | `pytorch-python313-cuda12_9-sm89-avx2` | `pytorch-python313-cuda12_9-sm89-avx512` |
| SM86 (Ampere) | A40, RTX 3090 | `pytorch-python313-cuda12_9-sm86-avx2` | `pytorch-python313-cuda12_9-sm86-avx512` |
| SM80 (Ampere) | A100, A30 | `pytorch-python313-cuda12_9-sm80-avx2` | `pytorch-python313-cuda12_9-sm80-avx512` |
| SM75 (Turing) | T4, RTX 2080 Ti | `pytorch-python313-cuda12_9-sm75-avx2` | `pytorch-python313-cuda12_9-sm75-avx512` |
| SM61 (Pascal) | P40, GTX 1080 Ti | `pytorch-python313-cuda12_9-sm61-avx2` | — |

> **Note:** SM61 (Pascal) only has an AVX2 variant. cuDNN is disabled for SM < 75 (cuDNN 9.11+ dropped support for older architectures).

### CPU-Only Builds (x86-64)

| Package Name | CPU ISA | Hardware Support |
|--------------|---------|------------------|
| `pytorch-python313-cpu-avx2` | AVX2 | Intel Haswell+ (2013), AMD Zen 1+ (2017) |
| `pytorch-python313-cpu-avx512` | AVX-512 | Intel Skylake-X+ (2017), AMD Zen 4+ (2022) |

### CPU-Only Builds (ARM)

| Package Name | CPU ISA | Hardware Support | Platform |
|--------------|---------|------------------|----------|
| `pytorch-python313-cpu-armv8_2` | ARMv8.2-A | Graviton2, Neoverse N1, Cortex-A75+ | `aarch64-linux` |
| `pytorch-python313-cpu-armv9` | ARMv9-A (SVE2) | Grace, Graviton3+, Neoverse V1/V2 | `aarch64-linux` |

### macOS (Apple Silicon)

| Package Name | Accelerator | Hardware Support | Platform |
|--------------|-------------|------------------|----------|
| `pytorch-python313-darwin-mps` | MPS (Metal) | Apple M1/M2/M3/M4 | `aarch64-darwin` |

## Building Variants

### GPU Builds (CUDA 12.9)

```bash
flox build pytorch-python313-cuda12_9-sm90-avx2
flox build pytorch-python313-cuda12_9-sm89-avx512
flox build pytorch-python313-cuda12_9-sm80-avx2
flox build pytorch-python313-cuda12_9-sm61-avx2
```

### CPU-Only Builds

```bash
flox build pytorch-python313-cpu-avx2
flox build pytorch-python313-cpu-avx512
flox build pytorch-python313-cpu-armv8_2
flox build pytorch-python313-cpu-armv9
```

### macOS Build

```bash
flox build pytorch-python313-darwin-mps
```

## Hardware Selection Guide

### Check Your GPU

```bash
nvidia-smi --query-gpu=name,compute_cap --format=csv,noheader
```

| Your GPU | Compute Cap | Use Build |
|----------|-------------|-----------|
| R100 | 12.0 | `...-sm120-avx2` or `...-sm120-avx512` |
| B200, GB200 | 10.0 | `...-sm100-avx2` or `...-sm100-avx512` |
| H100, H200, L40S | 9.0 | `...-sm90-avx2` or `...-sm90-avx512` |
| L40, RTX 4090 | 8.9 | `...-sm89-avx2` or `...-sm89-avx512` |
| A40, RTX 3090 | 8.6 | `...-sm86-avx2` or `...-sm86-avx512` |
| A100, A30 | 8.0 | `...-sm80-avx2` or `...-sm80-avx512` |
| T4, RTX 2080 Ti | 7.5 | `...-sm75-avx2` or `...-sm75-avx512` |
| P40, GTX 1080 Ti | 6.1 | `...-sm61-avx2` |
| Apple M1/M2/M3/M4 | N/A | `pytorch-python313-darwin-mps` |
| No GPU | N/A | `pytorch-python313-cpu-avx2` or `avx512` |

### Check Your CPU (x86-64)

```bash
lscpu | grep -E 'avx512|avx2'
```

- See `avx512f`? → Use AVX-512 variants for better performance
- See only `avx2`? → Use AVX2 variants

### Check Your CPU (ARM)

```bash
cat /proc/cpuinfo | grep -i 'sve2\|Features'
```

- SVE2 support (Graviton3+, Grace)? → Use `armv9` variant
- Older ARM (Graviton2)? → Use `armv8_2` variant

## Testing Your Build

```bash
# Test the built package
./test-build.sh pytorch-python313-cuda12_9-sm90-avx2

# Or test CPU build
./test-build.sh pytorch-python313-cpu-avx2
```

## Publishing to Flox Catalog

After successful builds:

```bash
# Ensure git remote is configured
git init
git add .
git commit -m "PyTorch 2.9.1 custom builds with CUDA 12.9"
git remote add origin <your-repo-url>
git push origin main

# Publish to your organization
flox publish -o <your-org> pytorch-python313-cuda12_9-sm90-avx2
flox publish -o <your-org> pytorch-python313-cpu-avx2

# Users install with:
flox install <your-org>/pytorch-python313-cuda12_9-sm90-avx2
```

## Build Times & Requirements

- **Time**: 1-3 hours per variant
- **Disk**: ~20GB per build
- **Memory**: 8GB+ RAM recommended

## Technical Details

### CUDA 12.9 Support

CUDA 12.9 provides support for all modern NVIDIA GPUs:
- Full support for architectures from Pascal (SM61) through Vera Rubin (SM120)
- Stable and well-tested in nixpkgs (`cudaPackages_12_9`)
- Compatible with a wide range of NVIDIA drivers

### Custom MAGMA

Each GPU build includes a custom per-SM static MAGMA library built specifically for its target architecture. This avoids shipping a fat MAGMA library with kernels for all GPU architectures and reduces closure size.

### Closure Stripping

GPU builds automatically strip build-time toolchain references (gcc-wrapper, gcc, binutils-wrapper, binutils) from the runtime closure, saving ~317 MiB per build. This is done via `disallowedReferences` and `remove-references-to` in the parametric builder.

### Parametric Builder

All CUDA builds use a shared parametric builder (`.flox/pkgs/lib/mkPyTorchCUDA.nix`) that takes `sm` and `isa` arguments. Individual `.nix` files in `.flox/pkgs/` are thin wrappers:

```nix
# Example: pytorch-python313-cuda12_9-sm90-avx2.nix
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "90"; isa = "avx2"; }
```

### BLAS Backends

- **GPU builds**: cuBLAS (via CUDA toolkit)
- **CPU builds (x86-64, ARM)**: OpenBLAS
- **macOS (MPS)**: vecLib (Apple Accelerate framework)

### PyTorch 2.9.1 Features

- Full CUDA 12.9 support
- Python 3.13 support
- Improved performance on modern hardware
- Better memory management

## Extending the Build Matrix

The parametric builder makes adding new variants straightforward. To add a new GPU variant:

1. Create a thin wrapper `.nix` file in `.flox/pkgs/`
2. Import the parametric builder with the desired `sm` and `isa`
3. Build with `flox build`

Example for a new SM architecture:
```nix
# .flox/pkgs/pytorch-python313-cuda12_9-sm<XX>-avx2.nix
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "<XX>"; isa = "avx2"; }
```

```bash
flox build pytorch-python313-cuda12_9-sm<XX>-avx2
```

The builder automatically handles MAGMA, closure stripping, and metadata based on the SM and ISA parameters. GPU metadata and CPU ISA definitions are in the shared `build-magma` repository.

## Troubleshooting

### Build fails with CUDA error

Verify CUDA 12.9 is being used — check build logs for `cudaPackages_12_9` in the overlay.

### Architecture mismatch

Ensure you're building for the correct GPU architecture. Use `nvidia-smi` to check your hardware.

### cuDNN errors on Pascal (SM61)

cuDNN 9.11+ dropped support for SM < 75. The builder automatically disables cuDNN for SM61 builds.

## Related Documentation

- [PyTorch 2.9 Release Notes](https://pytorch.org/blog/pytorch-2-9/)
- [CUDA 12 Documentation](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/)
- [Flox Documentation](https://flox.dev/docs/)

## License

This build environment configuration is MIT licensed. PyTorch itself is BSD-3-Clause licensed.
