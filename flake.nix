{
  description = "Breakwater with Socket2 patches";

  inputs = {
    nixpkgs.url = "github:bengsparks/nixpkgs/libvncserver";
    crate2nix.url = "github:bengsparks/crate2nix";
    crate2nix.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      crate2nix,
      rust-overlay,
      ...
    }@inputs:
    let
      supportedSystems = [
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
              overlays = [
                rust-overlay.overlays.default

                # Breakwater requires `nightly` due to `#![feature(portable_simd)]`.
                # `shell.nix` additionally overrides this to provide
                # `clippy` and `rust-src` to the developer for `rust-analyzer`
                (final: prev: {
                  rust-toolchain = final.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
                })
              ];
            };
          }
        );
    in
    {
      packages = forEachSupportedSystem (
        { pkgs }:
        let
          cargoDotNix = crate2nix.tools.${pkgs.system}.generatedCargoNix {
            name = "breakwater";
            src = ./.;
            cargo = pkgs.rust-toolchain;
          };
          rust = pkgs.callPackage ./. { inherit cargoDotNix; };
        in
        {
          default = rust.breakwater-vnc;
          breakwater-egui = rust.breakwater-egui;
          breakwater-vnc = rust.breakwater-vnc;
          socket2 = rust.breakwater-socket2;
          vpp = pkgs.vpp;
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
