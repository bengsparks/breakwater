{
  pkgs,
  craneLib,
  ...
}:
let
  inherit (pkgs) lib;
  src = craneLib.cleanCargoSource ./.;

  commonArgs = {
    inherit src;
    strictDeps = true;

    nativeBuildInputs = (
      with pkgs;
      [
        pkg-config
        clang
      ]
    );
    buildInputs = (
      with pkgs;
      [
        libclang
        libvncserver
        libvncserver.dev
      ]
    );
    doCheck = false;

    env.LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
  };

  # Build *just* the cargo dependencies (of the entire workspace),
  # so we can reuse all of that work (e.g. via cachix) when running in CI
  # It is *highly* recommended to use something like cargo-hakari to avoid
  # cache misses when building individual top-level-crates
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  individualCrateArgs = commonArgs // {
    inherit cargoArtifacts;
    inherit (craneLib.crateNameFromCargoToml { inherit src; }) version;
    doCheck = false;
  };
in
{
  breakwater = craneLib.buildPackage (
    individualCrateArgs
    // {
      pname = "breakwater";
      cargoExtraArgs = "-p breakwater";
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions ([
          # Cargo files
          ./Cargo.toml
          ./Cargo.lock
          # Workspace members
          (craneLib.fileset.commonCargoSources ./breakwater-egui-overlay)
          (craneLib.fileset.commonCargoSources ./breakwater-parser)
          (craneLib.fileset.commonCargoSources ./breakwater-parser-c-bindings)
          (craneLib.fileset.commonCargoSources ./breakwater)
          # Resources included via include_*
          ./breakwater/src/sinks/egui/canvas.vert
          ./breakwater/src/sinks/egui/canvas.frag
          ./breakwater/Arial.ttf
        ]);
      };

      CARGO_BUILD_TARGET = "aarch64-unknown-linux-musl";
      CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
    }
  );
}
