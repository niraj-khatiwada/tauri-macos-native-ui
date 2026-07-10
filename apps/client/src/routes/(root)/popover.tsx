import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";
import { useTitlebarSize } from "~/hooks/useWindowTitlebarSize";

export const Route = createFileRoute("/(root)/popover")({
  component: Popover,
});

function Popover() {
  const titlebarHeight = useTitlebarSize();

  const handleWindowPopver = async (evt: any) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_window_popover", {
      x: rect.left + rect.width / 2,
      y: rect.bottom + titlebarHeight,
      width: 500,
      height: 300,
    });
  };

  const handleNativePopver = async (evt: any) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_native_popover", {
      x: rect.left + rect.width / 2,
      y: rect.bottom + titlebarHeight,
      width: 350,
      height: 250,
    });
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="h-screen w-screen flex flex-col items-center justify-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit absolute top-1/2 left-1/2"
          onClick={handleWindowPopver}
        >
          Open Window Popver
        </button>
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit absolute top-4 right-4"
          onClick={handleNativePopver}
        >
          Open Native Popver
        </button>
      </div>
    </section>
  );
}
