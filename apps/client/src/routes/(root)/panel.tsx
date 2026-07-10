import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";
import { useTitlebarSize } from "~/hooks/useWindowTitlebarSize";

export const Route = createFileRoute("/(root)/panel")({
  component: Panel,
});

function Panel() {
  const titlebarHeight = useTitlebarSize();

  const handleWindowPanelShow = async (
    evt: any,
    panelId: string,
    liquidGlassEffect = false,
  ) => {
    const rect = evt.target.getBoundingClientRect();
    invoke("open_window_panel", {
      panelId,
      x: rect.left + rect.width / 2,
      y: rect.bottom + titlebarHeight,
      width: 500,
      height: 300,
      liquidGlassEffect,
    });
  };

  const handleWindowPanelHide = async (panelId: string) => {
    invoke("close_window_panel", {
      panelId,
    });
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full flex flex-col items-center justify-center gap-2 overflow-y-auto text-white">
        <div className="w-full flex items-center justify-center gap-2 text-white text-xs">
          <button
            onClick={(evt) => handleWindowPanelShow(evt, "1")}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Open Window Panel 1
          </button>

          <button
            onClick={() => handleWindowPanelHide("1")}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Close Window Panel 1
          </button>
        </div>
        <div className="w-full flex items-center justify-center gap-2 overflow-y-auto text-white mt-10">
          <button
            onClick={(evt) => handleWindowPanelShow(evt, "2", true)}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Open Window Panel 2
            <br />
            Liquid Glass
          </button>

          <button
            onClick={() => handleWindowPanelHide("2")}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Close Window Panel 2
            <br />
            Liquid Glass
          </button>
        </div>
      </div>
    </section>
  );
}
