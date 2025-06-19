{
  pkgs,
  system,
  crane,
  rust-overlay,
  buildWithMusl ? true,
}:
let
  inherit (pkgs)
    lib
    symlinkJoin
    ;

  buildTarget =
    if system == "x86_64-linux" && buildWithMusl then
      "x86_64-unknown-linux-musl"
    else if system == "aarch64-linux" && buildWithMusl then
      "aarch64-unknown-linux-musl"
    else if system == "x86_64-linux" && !buildWithMusl then
      "x86_64-unknown-linux-gnu"
    else if system == "aarch64-linux" && !buildWithMusl then
      "aarch64-unknown"
    else
      system;

  craneLib = (crane.mkLib pkgs).overrideToolchain (
    p:
    (p.rust-bin.selectLatestNightlyWith (
      t:
      t.default.override (attrs: {
        targets = attrs.targets ++ [ (builtins.trace buildTarget buildTarget) ];
      })
    ))
  );

  commonArgs = {
    strictDeps = true;

    nativeBuildInputs = (with pkgs; [ clang ]) ++ (with pkgs.pkgsStatic.pkgsMusl; [ pkg-config ]);
    buildInputs = (with pkgs.pkgsStatic.pkgsMusl; [ (libvncserver.override { withSystemd = false; }) ]);

    env.LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";

    CARGO_BUILD_TARGET = buildTarget;
    CARGO_BUILD_RUSTFLAGS = lib.optionalString buildWithMusl "-C target-feature=+crt-static";
  };

  mkPackage =
    src:
    let
      cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { inherit src; });
    in
    craneLib.buildPackage (
      commonArgs
      // {
        inherit src cargoArtifacts;
        inherit (craneLib.crateNameFromCargoToml { inherit src; }) version;
        doCheck = false;
      }
    );
in
{
  breakwater = mkPackage (
    lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions ([
        # Cargo files
        ./Cargo.toml
        ./Cargo.lock
        # Workspace members
        (craneLib.fileset.commonCargoSources ./breakwater-egui-overlay)
        (craneLib.fileset.commonCargoSources ./breakwater-parser)
        (craneLib.fileset.commonCargoSources ./breakwater)
        # Resources included via include_*
        ./breakwater/src/sinks/egui/canvas.vert
        ./breakwater/src/sinks/egui/canvas.frag
        ./breakwater/Arial.ttf
      ]);
    }
  );
}
