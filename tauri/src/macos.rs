#[cfg(target_os = "macos")]
use objc2_app_kit::{NSWindow, NSWindowButton};

// Hide the native traffic light buttons
#[cfg(target_os = "macos")]
pub fn hide_traffic_light_buttons(window: &tauri::WebviewWindow<tauri::Wry>) {
    if let Ok(ns_window_ptr) = window.ns_window() {
        unsafe {
            let ns_window = &*(ns_window_ptr as *const NSWindow);

            if let Some(close_btn) = ns_window.standardWindowButton(NSWindowButton::CloseButton) {
                close_btn.setHidden(true);
            }
            if let Some(mini_btn) =
                ns_window.standardWindowButton(NSWindowButton::MiniaturizeButton)
            {
                mini_btn.setHidden(true);
            }
            if let Some(zoom_btn) = ns_window.standardWindowButton(NSWindowButton::ZoomButton) {
                zoom_btn.setHidden(true);
            }
        }
    }
}
