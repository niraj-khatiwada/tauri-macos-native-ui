use once_cell::sync::Lazy;
use std::sync::Mutex;
use tauri::{
    tray::{MouseButton, MouseButtonState, TrayIconEvent},
    webview::PageLoadEvent,
    AppHandle, Manager, WebviewUrl, WebviewWindow, WebviewWindowBuilder,
};

use crate::tray_popover::WindowExt;

mod commands;
mod domain;
mod macos_bridge;
mod tray_popover;

static TAURI_APP_HANDLE: Lazy<Mutex<Option<AppHandle>>> = Lazy::new(|| Mutex::new(None));

fn create_tray_window(app_handle: &AppHandle, label: &str) -> Result<WebviewWindow, String> {
    let tray_url = if let Some(main_window) =
        app_handle.get_webview_window(domain::AppWindow::Main.as_str())
    {
        let mut url = main_window.url().map_err(|err| err.to_string())?;
        url.set_fragment(Some(&domain::AppWindow::Tray.get_webview_url()));
        WebviewUrl::CustomProtocol(url)
    } else {
        WebviewUrl::App(format!("index.html#{}", label).into())
    };

    let tray_window = WebviewWindowBuilder::new(app_handle, label, tray_url)
        .decorations(false)
        .transparent(true)
        .visible(false)
        .inner_size(400.0, 500.0)
        .build()
        .map_err(|err| err.to_string())?;

    Ok(tray_window)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            commands::resize_window,
            commands::open_native_menu,
            commands::open_window_popover,
            commands::close_window_popover,
            commands::is_window_popover_visible,
            commands::open_window_panel,
            commands::close_window_panel,
            commands::is_window_panel_visible,
            commands::resize_window_panel,
            commands::open_native_popover,
            commands::open_native_tooltip,
            commands::close_native_tooltip,
            commands::trigger_trackpad_haptic,
            commands::open_native_toast,
            commands::open_tray_popover,
            commands::close_tray_popover,
            commands::open_window_as_modal_sheet,
            commands::resize_window_as_modal_sheet,
            commands::close_window_as_modal_sheet,
            commands::is_tray_popover_visible,
            commands::resize_tray_popover,
            commands::open_alert_dialog,
            commands::close_alert_dialog,
            commands::focus_or_create_main_window,
            commands::quit_app,
        ])
        .setup(|app| {
            let app_handle = app.handle();
            let app_handle_clone = app_handle.clone();

            if let Ok(mut guard) = TAURI_APP_HANDLE.lock() {
                *guard = Some(app_handle_clone);
            }

            let main_window = app_handle
                .get_webview_window(domain::AppWindow::Main.as_str())
                .expect("main window must exist");
            macos_bridge::hide_traffic_light_buttons(&main_window);

            let tray_window_label = domain::AppWindow::Tray.as_str();
            let tray_window =
                create_tray_window(&app_handle, tray_window_label).expect("tray window must exist");

            tray_popover::init(app);
            let _ = tray_window.to_popover();

            let app_handle_clone = app_handle.clone();
            let tray = app
                .tray_by_id(tray_window_label) // tray id from tauri.conf.json
                .expect("tray window must exist");
            tray.on_tray_icon_event(move |_, event| match event {
                TrayIconEvent::Click {
                    button,
                    button_state,
                    ..
                } => {
                    if button == MouseButton::Left && button_state == MouseButtonState::Up {
                        let window_option = if let Some(window) =
                            app_handle_clone.get_webview_window(tray_window_label)
                        {
                            Some(window)
                        } else {
                            // tray was probably suspended -> create new tray window
                            match create_tray_window(&app_handle_clone, tray_window_label) {
                                Ok(window) => match window.to_popover() {
                                    Ok(_) => Some(window),
                                    Err(_) => None,
                                },
                                Err(_) => None,
                            }
                        };
                        if let Some(window) = window_option {
                            match window.toggle_tray_popover() {
                                Ok(_) => {}
                                Err(_) => {}
                            }
                        }
                    }
                }
                _ => {}
            });

            Ok(())
        })
        .on_page_load(|window, payload| {
            if let PageLoadEvent::Finished = payload.event() {
                if window.label().eq(domain::AppWindow::Main.as_str()) {
                    let _ = window.window().show();
                    let __ = window.window().set_focus();
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
