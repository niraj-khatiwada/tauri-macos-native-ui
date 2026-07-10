import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";
import { useTitlebarSize } from "~/hooks/useWindowTitlebarSize";

export const Route = createFileRoute("/(root)/tooltip")({
  component: Tooltip,
});

function Tooltip() {
  const titlebarHeight = useTitlebarSize();

  const handleMouseEnter = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();

    invoke("open_native_tooltip", {
      text: "About Menu",
      keys: ["⇧", "⌘", "K"],
      x: rect.left + rect.width / 2,
      y: rect.top - rect.height - 5 + titlebarHeight,
    });

    invoke("trigger_trackpad_haptic");
  };

  const handleMouseLeave = () => {
    invoke("close_native_tooltip");
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full h-screen flex flex-col gap-2 overflow-y-auto text-white">
        <div
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit absolute top-5 left-1/2 translate-x-1/2"
          onMouseEnter={handleMouseEnter}
          onMouseLeave={handleMouseLeave}
        >
          Hover Over
        </div>
        <p className="text-white mt-14 text-center">
          Notice the tooltip floats beyond main window.
        </p>
      </div>
    </section>
  );
}
