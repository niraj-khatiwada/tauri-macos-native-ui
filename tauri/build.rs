fn main() {
    #[cfg(target_os = "macos")]
    {
        // 1. Tell the dynamic linker (dyld) where to find Swift system libraries at runtime
        println!("cargo:rustc-link-arg=-Wl,-rpath,/usr/lib/swift");
        println!("cargo:rustc-link-arg=-Wl,-rpath,/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx");

        swift_rs::SwiftLinker::new("15.0")
            .with_package("swift-bridge", "./swift-bridge")
            .link();
    }
    tauri_build::build()
}
