import { createFileRoute } from "@tanstack/react-router";
import { Sidebar } from "./Sidebar";
import { invoke } from "@tauri-apps/api/core";

export const Route = createFileRoute("/(root)/")({
  component: App,
});

function App() {
  const resizeWindow = async () => {
    await invoke("resize_window", {
      width: Math.max(300, Math.random() * 1000),
      height: Math.max(300, Math.random() * 1000),
    });
  };
  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full h-full flex items-center justify-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs"
          onClick={resizeWindow}
        >
          Resize Window
        </button>
      </div>
    </section>
  );
}
