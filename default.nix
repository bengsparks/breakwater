{
  pkgs,
  cargoDotNix ? ./Cargo.nix,
  ...
}:
let
  cargoNix = import cargoDotNix {
    inherit pkgs;
    buildRustCrateForPkgs =
      pkgs:
      pkgs.buildRustCrate.override {
        defaultCrateOverrides = pkgs.defaultCrateOverrides // {
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
                libvncserver.dev
              ]);

            env = {
              LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
              LIBVNCSERVER_HEADER_FILE = "${pkgs.libvncserver.dev}/include/rfb/rfb.h";
            };
          };
        };
        rustc = pkgs.rust-toolchain;
        cargo = pkgs.rust-toolchain;
      };
  };

  workspace = cargoNix.workspaceMembers;

  breakwater = workspace.breakwater.build;
in
{
  breakwater-egui = breakwater.override { features = [ "egui" ]; };
  breakwater-vnc = breakwater.override { features = [ "vnc" ]; };
}
