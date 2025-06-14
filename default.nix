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
            nativeBuildInputs = (attrs.nativeBuildInputs or []) ++ (with pkgs; [
              pkg-config
            ]);

            buildInputs = (attrs.buildInputs or []) ++ (with pkgs; [
              libvncserver
              libvncserver.dev
            ]);
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
  breakwater-egui = breakwater.override { features = ["egui"];  };
  breakwater-vnc = breakwater.override { features = ["vnc"];  };
}
