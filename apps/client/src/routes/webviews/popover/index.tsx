import { invoke } from "@tauri-apps/api/core";
import { useState } from "react";

import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/webviews/popover/")({
  component: PopoverWindow,
});

export default function PopoverWindow() {
  const [counter, setCounter] = useState<number>(0);

  const handleCopySuccess = () => {
    invoke("open_native_toast", {
      text: "Copied configuration token to clipboard",
      icon: "doc.on.doc.fill",
      iconHex: "#10B981",
    });
  };

  const handleSaveError = () => {
    invoke("open_native_toast", {
      text: "Failed to connect to database runtime",
      icon: "exclamationmark.triangle.fill",
      iconHex: "#FF6060",
    });
  };

  const handleClosePopover = () => {
    invoke("close_window_popover");
  };

  return (
    <div className="p-4 w-screen h-screen">
      <div className="w-full flex items-center justify-center gap-2 text-white text-xs">
        <button
          onClick={() => {
            setCounter((s) => s + 1);
          }}
        >
          Click {counter}
        </button>
        <button
          onClick={handleCopySuccess}
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
        >
          Show Success Toast
        </button>

        <button
          onClick={handleSaveError}
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
        >
          Show Error Toast
        </button>
      </div>
      <p className="text-white my-4 text-center">
        Notice that this popover floats beyond the main window
      </p>
      <div className="w-full flex items-center justify-center gap-2 text-white text-xs">
        <button
          onClick={handleClosePopover}
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
        >
          Close Popover
        </button>
      </div>
    </div>
  );
}
