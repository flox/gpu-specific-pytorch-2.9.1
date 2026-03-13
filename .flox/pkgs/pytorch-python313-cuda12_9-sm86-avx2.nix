# PyTorch 2.9.1 for NVIDIA Ampere (SM86) -- avx2 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "86"; isa = "avx2"; }
