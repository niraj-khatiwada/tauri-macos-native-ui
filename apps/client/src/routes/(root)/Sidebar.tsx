import { Link } from "@tanstack/react-router";
import Icon from "~/components/Icon";

const navigationItems = [
  {
    name: "Menu",
    path: "/menu",
    icon: <Icon name="chat-bubble" />,
  },
  {
    name: "Popover",
    path: "/popover",
    icon: <Icon name="chat-bubble" />,
  },
  { name: "Panel", path: "/panel", icon: <Icon name="rectangle" /> },
  { name: "Toast", path: "/toast", icon: <Icon name="toast" /> },
  { name: "Tooltip", path: "/tooltip", icon: <Icon name="chat-bubble" /> },
  {
    name: "Apple Intelligence",
    path: "/apple-intelligence",
    icon: <Icon name="ai" />,
  },
];

export function Sidebar() {
  return (
    <aside className="w-full h-screen bg-[#F5F5F7]/90 dark:bg-[#1E1E1F]/20 border-r border-[#E5E5EA] dark:border-[#2C2C2E] flex flex-col justify-between p-3 select-none font-sans antialiased">
      <div className="space-y-6">
        <nav className="space-y-0.5">
          {navigationItems.map((item) => {
            return (
              <Link
                key={item.path}
                to={item.path}
                className="flex items-center gap-1 px-3 py-1.5 rounded-xl text-[14px] font-medium transition-colors duration-150 group outline-none text-white bg-zinc-800/50"
                inactiveProps={{
                  className:
                    "text-[#3A3A3C] dark:text-zinc-100 dark:bg-transparent hover:bg-[#E8E8ED] dark:hover:bg-zinc-800/50",
                }}
              >
                <div className="-mb-0.5">{item.icon}</div>
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>
      </div>
    </aside>
  );
}
