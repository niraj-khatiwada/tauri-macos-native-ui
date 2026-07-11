import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";

export const Route = createFileRoute("/(root)/alert")({
  component: Modal,
});

export type AlertButtonType = "default" | "info" | "warning";

export interface AlertActionButton {
  id: string;
  label: string;
  type: AlertButtonType;
}

export interface NativeAlertPayload {
  id: string;
  title: string;
  description: string;
  buttons: AlertActionButton[];
  detached?: boolean;
}

function Modal() {
  const handleWindowAsModalSheetOpen = async (detached = false) => {
    await invoke("open_alert_dialog", {
      id: "psroject_deletion_check",
      title: "Are you absolutely sure?",
      description:
        "This action cannot be undone. You will lose all saved workspace state history.",
      buttons: [
        { id: "cancel_btn", label: "Keep Project", type: "info" },
        { id: "delete_btn", label: "Delete Permanently", type: "warning" },
        { id: "cancel_btn", label: "Cancel", type: "default" },
      ],
      detached,
    } satisfies NativeAlertPayload);
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full h-full flex items-center justify-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs"
          onClick={() => handleWindowAsModalSheetOpen(false)}
        >
          Show Alert
        </button>
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs"
          onClick={() => handleWindowAsModalSheetOpen(true)}
        >
          Show Detached Alert
        </button>
      </div>
    </section>
  );
}
