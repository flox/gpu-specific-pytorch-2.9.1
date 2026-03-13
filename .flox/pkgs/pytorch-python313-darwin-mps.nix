# PyTorch 2.9.1 with MPS (Metal Performance Shaders) for Apple Silicon
# Package name: pytorch-python313-darwin-mps
#
# macOS build for Apple Silicon (M1/M2/M3/M4) with Metal GPU acceleration
# Hardware: Apple M1, M2, M3, M4 and variants (Pro, Max, Ultra)
# Requires: macOS 12.3+

{ python3Packages
, lib
, fetchFromGitHub
}:

(python3Packages.pytorch.override {
  cudaSupport = false;
}).overrideAttrs (oldAttrs: {
  pname = "pytorch-python313-darwin-mps";
  version = "2.9.1";

  src = fetchFromGitHub {
    owner = "pytorch";
    repo = "pytorch";
    rev = "v2.9.1";
    hash = "sha256-MYzzceoQh01jzQU9tyAl47PU4M+QbuKwHXQAE8yt1Hg=";
    fetchSubmodules = true;
  };

  # Override patches - PyTorch 2.9.1 doesn't need 2.8.0 patches
  patches = [];

  # Override postPatch - skip the setuptools replacement that doesn't apply to 2.9.1
  postPatch = ''
    # Add necessary postPatch commands for PyTorch 2.9.1 if needed
  '';

  # Limit build parallelism to prevent memory saturation
  ninjaFlags = [ "-j32" ];
  requiredSystemFeatures = [ "big-parallel" ];

  passthru = oldAttrs.passthru // {
    gpuArch = "mps";
    blasProvider = "veclib";
    cpuISA = null;
  };

  # Filter out CUDA deps (base pytorch may include them)
  buildInputs = lib.filter (p: !(lib.hasPrefix "cuda" (p.pname or "")))
    (oldAttrs.buildInputs or []);

  nativeBuildInputs = lib.filter (p: p.pname or "" != "addDriverRunpath")
    (oldAttrs.nativeBuildInputs or []);

  preConfigure = (oldAttrs.preConfigure or "") + ''
    # Disable CUDA
    export USE_CUDA=0
    export USE_CUDNN=0
    export USE_CUBLAS=0

    # Enable MPS (Metal Performance Shaders)
    export USE_MPS=1
    export USE_METAL=1

    # Use vecLib (Apple Accelerate) for BLAS
    export BLAS=vecLib
    export MAX_JOBS=32

    echo "========================================="
    echo "PyTorch 2.9.1 Build Configuration"
    echo "========================================="
    echo "GPU Target: MPS (Metal Performance Shaders)"
    echo "Platform: Apple Silicon (aarch64-darwin)"
    echo "BLAS Backend: vecLib (Apple Accelerate)"
    echo "Python: 3.13"
    echo "========================================="
  '';

  meta = oldAttrs.meta // {
    description = "PyTorch 2.9.1 with MPS GPU acceleration for Apple Silicon";
    longDescription = ''
      Custom PyTorch 2.9.1 build with targeted optimizations:
      - GPU: Metal Performance Shaders (MPS) for Apple Silicon
      - Platform: macOS 12.3+ on M1/M2/M3/M4
      - BLAS: vecLib (Apple Accelerate framework)
      - Python: 3.13
    '';
    platforms = [ "aarch64-darwin" ];
  };
})
