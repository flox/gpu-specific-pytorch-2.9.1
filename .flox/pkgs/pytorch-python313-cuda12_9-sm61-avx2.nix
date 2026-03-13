# PyTorch 2.9.1 for NVIDIA Pascal (SM61) -- avx2 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "61"; isa = "avx2"; }
