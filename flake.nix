{
  description = "Breakwater with Socket2 patches";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    crane.url = "github:ipetkov/crane";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      rust-overlay,
      ...
    }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ rust-overlay.overlays.default ];
            };
          }
        );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        let
          # Breakwater requires `nightly` due to `#![feature(portable_simd)]`.
          # `shell.nix` additionally overrides this to provide
          # `clippy` and `rust-src` to the developer for `rust-analyzer`
          craneLib = (crane.mkLib pkgs).overrideToolchain (
            p:
            p.buildPackages.rust-bin.selectLatestNightlyWith (
              toolchain:
              toolchain.default.override (pre: {
                targets = pre.targets ++ [ "aarch64-unknown-linux-musl" ];
              })
            )
          );

          rust = import ./. { inherit pkgs craneLib; };
        in
        {
          default = rust.breakwater;
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.callPackage ./shell.nix { };
        }
      );
    };
}
