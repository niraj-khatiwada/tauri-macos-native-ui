use std::{self, sync::Mutex};
use tauri::{tray::TrayIcon, Manager, Runtime, WebviewWindow};

use crate::macos_bridge::ffi;

pub trait WindowExt<R: Runtime> {
    fn to_popover(&self) -> Result<(), String>;
    fn is_tray_popover_visible(&self) -> bool;
    fn open_tray_popover(&self) -> Result<(), String>;
    fn close_tray_popover(&self) -> Result<(), String>;
    fn toggle_tray_popover(&self) -> Result<(), String>;
}

pub trait RawAppKitHandles {
    fn raw_statusbar_button(&self) -> Result<*mut std::ffi::c_void, String>;
}

impl<R: Runtime> RawAppKitHandles for TrayIcon<R> {
    fn raw_statusbar_button(&self) -> Result<*mut std::ffi::c_void, String> {
        struct SendPtr(*mut std::ffi::c_void);
        unsafe impl Send for SendPtr {}

        let send_ptr_result = self.with_inner_tray_icon(|inner| match inner.ns_status_item() {
            Some(status_item) => {
                let button: objc2::rc::Retained<objc2_app_kit::NSStatusBarButton> =
                    unsafe { objc2::msg_send![&*status_item, button] };
                let raw_ptr = objc2::rc::Retained::into_raw(button) as *mut std::ffi::c_void;

                Ok(SendPtr(raw_ptr))
            }
            None => Err("NSStatusItem instance was dropped or not initialized".to_string()),
        });

        match send_ptr_result {
            Ok(inner_result) => match inner_result {
                Ok(send_ptr) => Ok(send_ptr.0),
                Err(custom_err) => Err(custom_err),
            },
            Err(tauri_err) => Err(format!("Tauri tray runtime thread error: {}", tauri_err)),
        }
    }
}

impl<R: Runtime> WindowExt<R> for WebviewWindow<R> {
    fn to_popover(&self) -> Result<(), String> {
        let tray = self
            .app_handle()
            .tray_by_id(self.label())
            .ok_or_else(|| format!("Tray not found for label: {}", self.label()))?;

        let raw_button = tray.raw_statusbar_button().map_err(|err| err.to_string())?;
        let ns_window_ptr =
            self.ns_window().map_err(|err| err.to_string())? as *mut std::ffi::c_void;

        ffi::initTrayPopoverManager(ns_window_ptr, raw_button);

        let state = self.app_handle().state::<AppState>();
        *state.0.lock().map_err(|err| err.to_string())? = true;

        Ok(())
    }

    fn is_tray_popover_visible(&self) -> bool {
        let state = self.app_handle().state::<AppState>();
        if !*state.0.lock().unwrap() {
            return false;
        }

        ffi::isTrayPopoverVisible()
    }

    fn open_tray_popover(&self) -> Result<(), String> {
        let state = self.app_handle().state::<AppState>();
        if !*state.0.lock().map_err(|err| err.to_string())? {
            return Err("Tray reference not found".to_string());
        }

        ffi::openTrayPopover();

        Ok(())
    }

    fn close_tray_popover(&self) -> Result<(), String> {
        let state = self.app_handle().state::<AppState>();
        if !*state.0.lock().unwrap() {
            return Err("Tray reference not found".to_string());
        }

        ffi::closeTrayPopover();

        Ok(())
    }

    fn toggle_tray_popover(&self) -> Result<(), String> {
        if self.is_tray_popover_visible() {
            return Ok(self.close_tray_popover()?);
        } else {
            return Ok(self.open_tray_popover()?);
        }
    }
}

pub struct AppState(pub Mutex<bool>);

pub fn init<R: Runtime>(app: &tauri::App<R>) {
    app.manage(AppState(Mutex::new(false)));
}
