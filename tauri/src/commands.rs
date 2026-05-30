use tauri::window::{Effect, EffectsBuilder};
use tauri::Manager;
use tauri::{WebviewUrl, WebviewWindowBuilder};

use crate::macos;
use crate::swift_bridge::{show_native_popover, show_webview_popover};

#[tauri::command]
pub fn open_native_popover(app: tauri::AppHandle, x: f64, y: f64) {
    if let Some(main_window) = app.get_webview_window("main") {
        if let Ok(raw_ns_window_ptr) = main_window.ns_window() {
            unsafe {
                show_native_popover(raw_ns_window_ptr as *const std::ffi::c_void, x, y);
            }
        }
    }
}

#[tauri::command]
pub fn open_native_webview_popover(app: tauri::AppHandle, x: f64, y: f64) {
    #[cfg(target_os = "macos")]
    {
        if let Some(main_window) = app.get_webview_window("main") {
            // 1. Determine our final target routing string context based on environment
            let mut target_url_string = None;

            #[cfg(not(debug_assertions))]
            if let Ok(resource_dir) = app.path().resource_dir() {
                let html_path = resource_dir.join("dist").join("index.html");
                if html_path.exists() {
                    // Format: file:///path/to/dist/index.html#popover
                    target_url_string =
                        Some(format!("file://{}#popover", html_path.to_string_lossy()));
                }
            }

            // Fallback to Dev Server Strategy if production asset folder isn't found
            let final_url_string = match target_url_string {
                Some(prod_url) => prod_url,
                None => {
                    if let Ok(mut dev_url) = main_window.url() {
                        dev_url.set_fragment(Some("popover"));
                        dev_url.as_str().to_string()
                    } else {
                        "#popover".to_string()
                    }
                }
            };

            // 2. Convert the chosen URL path to a single SRString wrapper instance
            let final_path_sr = swift_rs::SRString::from(final_url_string.as_str());

            // 3. Hand everything off over the Swift bridge execution boundary safely
            if let Ok(raw_ns_window_ptr) = main_window.ns_window() {
                unsafe {
                    show_webview_popover(
                        raw_ns_window_ptr as *const std::ffi::c_void,
                        final_path_sr,
                        x,
                        y,
                        cfg!(debug_assertions),
                    );
                }
            }
        }
    }
}

#[tauri::command]
pub fn open_window_popover(app: tauri::AppHandle, x: f64, y: f64, width: f64, height: f64) {
    if let Some(window) = app.get_webview_window("popover_window") {
        println!("popover_window already exists. closing & creating a new one...");
        window.close().unwrap();
    } else {
        if let Some(main_window) = app.get_webview_window("main") {
            let position = main_window.outer_position().unwrap();
            let logical_position = position.to_logical::<f64>(main_window.scale_factor().unwrap());
            let mut popover_url = if let Some(main_win) = app.get_webview_window("main") {
                main_win.url().unwrap()
            } else {
                // Fallback safety string if main window is missing
                "https://tauri.localhost/index.html"
                    .parse::<tauri::Url>()
                    .unwrap()
            };

            popover_url.set_fragment(Some("popover"));
            let popover = WebviewWindowBuilder::new(
                &app,
                "popover_window",
                WebviewUrl::CustomProtocol(popover_url),
            )
            .parent(&main_window)
            .expect("Main parent window not found")
            .decorations(true)
            .transparent(true)
            .title_bar_style(tauri::TitleBarStyle::Overlay)
            .hidden_title(true)
            .always_on_top(true)
            .skip_taskbar(true)
            .resizable(false)
            .maximizable(false)
            .minimizable(false)
            .focused(true)
            .effects(
                EffectsBuilder::new()
                    .effect(Effect::Menu)
                    .state(tauri::window::EffectState::Active)
                    .radius(20.0)
                    .build(),
            )
            .inner_size(width, height)
            .position(logical_position.x as f64 + x, logical_position.y as f64 + y)
            .build()
            .unwrap();

            let popover_clone = popover.clone();
            let main_window_clone = main_window.clone();

            macos::hide_traffic_light_buttons(&popover);

            popover.on_window_event(move |event| match event {
                tauri::WindowEvent::Focused(false) => {
                    let _ = popover_clone.close();
                    let _ = main_window_clone.set_focus();
                }
                _ => {}
            });

            let main_window_clone = main_window.clone();
            let popover_main_clone = popover.clone();
            main_window.on_window_event(move |event| match event {
                tauri::WindowEvent::Destroyed | tauri::WindowEvent::Moved(..) => {
                    if let Some(pop_win) = popover_main_clone
                        .app_handle()
                        .get_webview_window("popover_window")
                    {
                        let _ = pop_win.close();
                        let _ = main_window_clone.set_focus();
                    }
                }

                _ => {}
            });
        }
    }
}

// New command to close any window dynamically by its string identifier
#[tauri::command]
pub fn close_window_popover(app: tauri::AppHandle, label: String) -> Result<(), String> {
    if let Some(window) = app.get_webview_window(&label) {
        window.close().map_err(|e| e.to_string())?;
        Ok(())
    } else {
        Err(format!("Window with label '{}' not found", label))
    }
}
