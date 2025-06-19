{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "dev-shell";

  packages = with pkgs; [
    # Fetching
    git

    # Building and formatting nix
    nix-output-monitor
    nixfmt-rfc-style

    # Needed for native-display feature
    wayland
    libGL
    libxkbcommon
  ];

  shellHook =
    ''
      export LIBCLANG_PATH="${pkgs.libclang.lib}/lib"
      export LIBVNCSERVER_HEADER_FILE="${pkgs.libvncserver.dev}/include/rfb/rfb.h"
      export WINIT_UNIX_BACKEND="wayland"
      export XDG_DATA_DIRS=${builtins.getEnv "XDG_DATA_DIRS"}
    ''
    +

      # required for `https://github.com/sbernauer/libvnc-rs.git`'s `build.rs`
      ''
        export LD_LIBRARY_PATH="${
          pkgs.lib.makeLibraryPath (
            with pkgs;
            [
              clang
              libclang
              libvncserver
              libvncserver.dev
            ]
          )
        }"
      '';
}
