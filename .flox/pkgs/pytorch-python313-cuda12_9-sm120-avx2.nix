# PyTorch 2.9.1 for NVIDIA Vera Rubin (SM120) -- avx2 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "120"; isa = "avx2"; }
