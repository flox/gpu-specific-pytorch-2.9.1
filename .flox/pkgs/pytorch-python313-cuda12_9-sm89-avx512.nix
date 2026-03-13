# PyTorch 2.9.1 for NVIDIA Ada Lovelace (SM89) -- avx512 -- CUDA 12.9
{ pkgs ? import <nixpkgs> {} }:
import ./lib/mkPyTorchCUDA.nix { sm = "89"; isa = "avx512"; }
