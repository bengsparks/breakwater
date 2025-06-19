{
  description = "Breakwater with Socket2 patches";

  inputs = {
    nixpkgs.url = "github:bengsparks/nixpkgs/libvncserver-tests";

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
          rust = import ./. {
            inherit (inputs) crane rust-overlay;
            inherit (pkgs) system;
            inherit pkgs;
            buildWithMusl = true;
          };
        in
        {
          default = rust.breakwater;
          lvs = (pkgs.pkgsStatic.pkgsMusl.libvncserver.override { withSystemd = false; });
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
