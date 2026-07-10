import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";

export const Route = createFileRoute("/(root)/toast")({
  component: Toast,
});

function Toast() {
  const handleCopySuccess = () => {
    invoke("open_native_toast", {
      text: "Copied configuration token to clipboard",
      icon: "doc.on.doc.fill",
      iconHex: "#10B981",
      // You can also pass toast position
      // Both % and absolute values are supported
      // (x=0.5, y=0.5) => center of the screen | (x=1.0, y=0.9) => bottom right of the screen
      // (x=100, y=200) => 100 from left & 200 from top of the screeen
      x: 1,
      y: 0.9,
    });
  };

  const handleSaveError = () => {
    invoke("open_native_toast", {
      text: "Failed to connect to database runtime",
      icon: "exclamationmark.triangle.fill",
      iconHex: "#FF6060",
    });
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full flex items-center justify-center gap-2 text-white text-xs">
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
    </section>
  );
}
