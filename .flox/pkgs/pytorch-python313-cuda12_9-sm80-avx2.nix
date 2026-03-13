# PyTorch 2.9.1 for NVIDIA Ampere (SM80) -- avx2 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "80"; isa = "avx2"; }
