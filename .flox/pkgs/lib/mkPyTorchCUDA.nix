# Parametric PyTorch CUDA builder
# Creates GPU-architecture-specific PyTorch builds with custom per-SM MAGMA
# and closure stripping (removes build-time toolchain references).
#
# Arguments:
#   sm:  SM architecture number (e.g., "90")
#   isa: CPU ISA key from cpu-isa.nix (e.g., "avx2", "avx512")
{ sm, isa }:

let
  # ── Lookup tables from build-magma (single source of truth) ──────────
  cpuISAs = import /home/daedalus/dev/builds/build-magma/.flox/pkgs/lib/cpu-isa.nix;
  gpuMeta = import /home/daedalus/dev/builds/build-magma/.flox/pkgs/lib/gpu-metadata.nix;

  # ── ISA configuration ────────────────────────────────────────────────
  isaConfig = cpuISAs.${isa};

  # ── GPU configuration ────────────────────────────────────────────────
  smMeta = gpuMeta.${sm};

  # ── Variant naming ───────────────────────────────────────────────────
  variantName = "pytorch-python313-cuda12_9-sm${sm}-${isa}";

  # ── cuDNN: disabled for SM < 7.5 (cuDNN 9.11+ dropped support) ──────
  smInt = builtins.fromJSON sm;
  disableCuDNN = smInt < 75;

  # ── Nixpkgs pin (matches build-magma and build-onnx-runtime) ─────────
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ed142ab1b3a092c4d149245d0c4126a5d7ea00b0.tar.gz";
  }) {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = [
      (final: prev: { cudaPackages = final.cudaPackages_12_9; })
    ];
  };

  inherit (nixpkgs_pinned) lib;

  # ── Custom MAGMA: single-SM static library from build-magma ──────────
  customMagma = import /home/daedalus/dev/builds/build-magma/.flox/pkgs/magma-cuda12_9-sm${sm}-${isa}.nix {};

in
  # Two-stage override:
  # 1. Enable CUDA, specify GPU targets, inject custom MAGMA
  (nixpkgs_pinned.python3Packages.torch.override {
    cudaSupport = true;
    gpuTargets = [ smMeta.capability ];
    effectiveMagma = customMagma;
  # 2. Customize build (CPU flags, metadata, closure stripping)
  }).overrideAttrs (oldAttrs: {
    pname = variantName;

    passthru = oldAttrs.passthru // {
      gpuArch = smMeta.capability;
      blasProvider = "cublas";
      cpuISA = isa;
    };

    # Limit build parallelism to prevent memory saturation
    ninjaFlags = [ "-j32" ];
    requiredSystemFeatures = [ "big-parallel" ];

    # Set CPU optimization flags + cuDNN disable for old SMs
    preConfigure = (oldAttrs.preConfigure or "") + ''
      export CXXFLAGS="${lib.concatStringsSep " " isaConfig.flags} $CXXFLAGS"
      export CFLAGS="${lib.concatStringsSep " " isaConfig.flags} $CFLAGS"
      export MAX_JOBS=32
    '' + lib.optionalString disableCuDNN ''

      # cuDNN 9.11+ dropped SM < 7.5 support
      export USE_CUDNN=0
    '' + ''

      echo "========================================="
      echo "PyTorch Build Configuration"
      echo "========================================="
      echo "GPU Target: ${smMeta.capability} (${smMeta.archName}: ${smMeta.gpuNames})"
      echo "CPU Features: ${isa}"
      echo "CUDA: 12.9 (cudaSupport=true, gpuTargets=[${smMeta.capability}])"
      echo "MAGMA: custom single-SM${sm} static library"
      echo "CXXFLAGS: $CXXFLAGS"
      echo "========================================="
    '';

    # ── Strip build-time toolchain from runtime closure (~317 MiB) ──────
    # gcc-wrapper/gcc leak via torch/_inductor/config.py (hardcoded CXX path)
    # binutils-wrapper/binutils leak via torch/csrc/profiler/unwind/unwind.cpp
    disallowedReferences = [
      nixpkgs_pinned.stdenv.cc     # gcc-wrapper
      nixpkgs_pinned.stdenv.cc.cc  # gcc (264 MiB)
    ];

    postFixup = (oldAttrs.postFixup or "") + ''
      echo "=== Stripping build-time references ==="
      build_time_refs=(
        "${nixpkgs_pinned.stdenv.cc}"                    # gcc-wrapper
        "${nixpkgs_pinned.stdenv.cc.cc}"                 # gcc (264 MiB)
        "${nixpkgs_pinned.stdenv.cc.bintools}"            # binutils-wrapper
        "${nixpkgs_pinned.stdenv.cc.bintools.bintools}"   # binutils (32 MiB)
      )
      for ref in "''${build_time_refs[@]}"; do
        echo "Stripping $ref from $out"
        find "$out" -type f -exec remove-references-to -t "$ref" '{}' +
        echo "Stripping $ref from ''${!outputLib}"
        find "''${!outputLib}" -type f -exec remove-references-to -t "$ref" '{}' +
      done
      echo "=== Done ==="
    '';

    meta = oldAttrs.meta // {
      description = "PyTorch for NVIDIA ${smMeta.gpuNames} (SM${sm}, ${smMeta.archName}) with ${isa} — CUDA 12.9 — custom MAGMA";
      platforms = [ isaConfig.platform ];
    };
  })
