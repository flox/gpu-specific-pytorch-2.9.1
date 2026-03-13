# PyTorch 2.9.1 for NVIDIA Hopper (SM90) -- avx512 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "90"; isa = "avx512"; }
