{
  description = "onnx-rust dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-python.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-python,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsPython = nixpkgs-python.legacyPackages.${system};

        python = pkgsPython.python313.withPackages (ps: [
          ps.optimum
          ps.onnx
          ps.onnxruntime
          ps.accelerate
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            python

            pkgs.rustc
            pkgs.cargo
            pkgs.clippy
            pkgs.rustfmt
            pkgs.rust-analyzer

            # openssl-sys, pulled in by ort's binary download
            pkgs.pkg-config
            pkgs.openssl
          ];

          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };
      }
    );
}
