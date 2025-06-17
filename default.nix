{
  pkgs,
  cargoDotNix ? ./Cargo.nix,
  ...
}:
let
  inherit (pkgs) rust-toolchain;

  overrides = {
    vncserver = attrs: {
      nativeBuildInputs =
        (attrs.nativeBuildInputs or [ ])
        ++ (with pkgs; [
          pkg-config
          clang
        ]);

      buildInputs =
        (attrs.buildInputs or [ ])
        ++ (with pkgs; [
          libvncserver
        ]);

      env = {
        LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
        LIBVNCSERVER_HEADER_FILE = "${pkgs.libvncserver.dev}/include/rfb/rfb.h";
      };
    };

    # This affects the vendored version of `socket2`, called `breakwater-socket2`, which links against
    # `-lvcl_ldpreload` from the `pkgs.vpp` package.
    socket2 = attrs: {
      buildInputs =
        (attrs.buildInputs or [ ])
        ++ (with pkgs; [
          vpp
        ]);

      env.VPP_LIBS = "${pkgs.vpp}/lib";
    };
  };

  cargoNix = import cargoDotNix {
    inherit pkgs;
    buildRustCrateForPkgs =
      pkgs:
      pkgs.buildRustCrate.override {
        defaultCrateOverrides = pkgs.defaultCrateOverrides // overrides;
        rustc = rust-toolchain;
        cargo = rust-toolchain;
      };
  };

  workspace = cargoNix.workspaceMembers;

  breakwater = workspace.breakwater.build;
in
{
  breakwater-egui = breakwater.override { features = [ "egui" ]; };
  breakwater-vnc = breakwater.override { features = [ "vnc" ]; };
  breakwater-socket2 = workspace.socket2.build;
}
