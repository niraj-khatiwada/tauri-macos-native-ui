import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";

export const Route = createFileRoute("/(root)/modal")({
  component: Modal,
});

function Modal() {
  const handleWindowAsModalSheetOpen = async () => {
    await invoke("open_window_as_modal_sheet", {
      width: 500,
      height: 600,
    });
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="h-screen flex flex-col items-center justify-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          onClick={handleWindowAsModalSheetOpen}
        >
          Open Modal Sheet
        </button>
      </div>
    </section>
  );
}
