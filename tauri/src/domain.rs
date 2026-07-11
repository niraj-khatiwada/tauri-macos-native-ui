#[derive(Debug, PartialEq, Eq)]
pub enum AppWindow {
    Main,
    Popover,
    Tray,
    Panel,
    Modal,
}

impl AppWindow {
    pub fn as_str(&self) -> &'static str {
        match self {
            AppWindow::Main => "main",
            AppWindow::Popover => "popover",
            AppWindow::Tray => "tray",
            AppWindow::Panel => "panel",
            AppWindow::Modal => "modal",
        }
    }

    pub fn get_panel_window_label_by_id(&self, panel_id: &str) -> String {
        if self.eq(&AppWindow::Panel) {
            format!("{}-{}", self.as_str(), panel_id)
        } else {
            self.as_str().to_string()
        }
    }

    pub fn get_webview_url(&self) -> String {
        format!("webviews/{}", self.as_str())
    }

    pub fn get_panel_window_webview_url(&self, panel_id: &str) -> String {
        let webview_url = self.get_webview_url();
        if self.eq(&AppWindow::Panel) {
            return format!("{}/{}", webview_url, panel_id);
        }
        webview_url
    }
}

#[derive(serde::Serialize, serde::Deserialize, Debug, Clone)]
pub struct NativeAlertActionButton {
    pub id: String,
    pub label: String,
    pub r#type: String, // "default" | "info" | "warning"
}
