extern crate pkg_config;

fn main() {
    let lib_path = std::env::var("VPP_LIBS").unwrap();
    let lib_path = std::path::PathBuf::from(lib_path);

    println!("cargo:rustc-link-search={}", lib_path.display());
    println!("cargo:rustc-link-lib=dylib=vcl_ldpreload");
}