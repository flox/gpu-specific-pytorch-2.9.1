# PyTorch 2.9.1 for NVIDIA Turing (SM75) -- avx512 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "75"; isa = "avx512"; }
