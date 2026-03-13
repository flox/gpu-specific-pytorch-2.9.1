# PyTorch 2.9.1 for NVIDIA Blackwell (SM100) -- avx2 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "100"; isa = "avx2"; }
