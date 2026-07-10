import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";

export const Route = createFileRoute("/(root)/apple-intelligence")({
  component: AppleIntelligence,
});

function AppleIntelligence() {
  const showAIGlowEffect = () => {
    invoke("show_ai_glow_effect");
  };

  const hideAIGlowEffect = () => {
    invoke("hide_ai_glow_effect");
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full h-screen flex flex-col items-center justify-center gap-2 overflow-y-auto text-white">
        <div className="w-full flex items-center justify-center gap-2 text-white text-xs">
          <button
            onClick={showAIGlowEffect}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Show Apple Intelligence
          </button>

          <button
            onClick={hideAIGlowEffect}
            className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          >
            Hide Apple Intelligence
          </button>
        </div>
      </div>
    </section>
  );
}
