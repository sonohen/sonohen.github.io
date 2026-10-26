{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShellNoCC {
  packages = [
    pkgs.hugo
    pkgs.git
  ];
}
