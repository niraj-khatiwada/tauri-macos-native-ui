import { createFileRoute } from "@tanstack/react-router";
import { invoke } from "@tauri-apps/api/core";
import { Sidebar } from "./Sidebar";
import { useTitlebarSize } from "~/hooks/useWindowTitlebarSize";

export const Route = createFileRoute("/(root)/menu")({
  component: Menu,
});

type MenuItem = {
  id: string;
  title: string;
  disabled?: boolean;
  checked?: boolean;
  items?: MenuItem[];
};

function Menu() {
  const titlebarHeight = useTitlebarSize();

  const handleOpenMenu = async (e: React.MouseEvent<HTMLButtonElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();

    const menuData: MenuItem[] = [
      { id: "cut", title: "Cut" },
      { id: "copy", title: "Copy" },
      {
        id: "settings",
        title: "Preferences",
        items: [{ id: "theme", title: "Toggle Dark Mode" }],
      },
    ];

    try {
      await invoke("open_native_menu", {
        x: rect.left,
        y: rect.bottom + 10 + titlebarHeight,
        items: menuData,
      });
    } catch (error) {
      console.error("Failed to trigger context menu:", error);
    }
  };

  const handleContextMenu = async (event: React.MouseEvent) => {
    event.preventDefault();

    const x = event.clientX;
    const y = event.clientY;

    const menuData: MenuItem[] = [
      { id: "cut", title: "Cut" },
      { id: "disabled", title: "Enable", checked: true },
      {
        id: "settings",
        title: "Preferences",
        items: [
          {
            id: "theme",
            title: "Toggle Dark Mode",
            items: [{ id: "theme2", title: "Toggle Dark Mode" }],
          },
        ],
      },
    ];

    try {
      await invoke("open_native_menu", { x, y, items: menuData });
    } catch (error) {
      console.error("Failed to open native menu:", error);
    }
  };

  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div className="w-full h-screen flex flex-col justify-center items-center gap-2 overflow-y-auto text-white">
        <button
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit"
          onClick={handleOpenMenu}
        >
          Open Native Menu
        </button>
        <div
          className="w-[75%] h-40 bg-zinc-900/25 rounded-xl mt-10 text-white/50 flex justify-center items-center select-none text-[14px]"
          onContextMenu={handleContextMenu}
        >
          Context Menu (Right-Click Me)
        </div>
      </div>
    </section>
  );
}
