import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";

export const Route = createFileRoute("/(root)/")({
  component: App,
});

function App() {
  const handleWindowPopver = async (evt: any) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_window_popover", {
      x: rect.left,
      y: rect.bottom,
      width: 350,
      height: 250,
    });
  };

  const handleNativePopver = async (evt: any) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_native_popover", {
      x: rect.left + rect.width / 2,
      y: rect.bottom,
      width: 350,
      height: 250,
    });
  };

  const handleNativePopverWebview = async (evt: any) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_native_webview_popover", {
      x: rect.left + rect.width / 2,
      y: rect.bottom,
      width: 350,
      height: 250,
    });
  };

  return (
    <>
      <div className="h-screen w-screen flex items-center justify-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          onClick={handleWindowPopver}
        >
          Create Window Popver
        </button>
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          onClick={handleNativePopver}
        >
          Create Native Popver
        </button>
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          onClick={handleNativePopverWebview}
        >
          Create Native Popver Webview
        </button>
      </div>
    </>
  );
}
