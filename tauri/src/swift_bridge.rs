swift_rs::swift!(pub fn show_native_popover(window_ptr: *const std::ffi::c_void, x: f64, y: f64));

swift_rs::swift!(
    pub fn show_webview_popover(
        window_ptr: *const std::ffi::c_void,
        url: swift_rs::SRString,
        x: f64,
        y: f64,
        enable_dev_tools: swift_rs::Bool
    )
);
