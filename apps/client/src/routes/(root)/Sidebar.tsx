import { Link } from "@tanstack/react-router";
import Icon from "~/components/Icon";

const navigationItems = [
  {
    name: "Home",
    path: "/",
    icon: <Icon name="home" />,
  },
  {
    name: "Menu",
    path: "/menu",
    icon: <Icon name="menu" />,
  },
  {
    name: "Popover",
    path: "/popover",
    icon: <Icon name="chat-bubble" />,
  },
  { name: "Panel", path: "/panel", icon: <Icon name="rectangle" /> },
  {
    name: "Modal",
    path: "/modal",
    icon: <Icon name="rectangle" className="rotate-90" />,
  },
  { name: "Toast", path: "/toast", icon: <Icon name="toast" /> },
  { name: "Tooltip", path: "/tooltip", icon: <Icon name="chat-bubble" /> },
  { name: "Alert", path: "/alert", icon: <Icon name="bell" /> },
];

export function Sidebar() {
  return (
    <aside className="w-full h-screen bg-[#F5F5F7]/20 dark:bg-[#1E1E1F]/20 border-r border-[#E5E5EA] dark:border-[#2C2C2E] flex flex-col justify-between py-4 px-2 select-none font-sans antialiased">
      <div className="space-y-6">
        <nav className="space-y-0.5">
          {navigationItems.map((item) => {
            return (
              <Link
                key={item.path}
                to={item.path}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-[12px] font-medium transition-colors duration-150 group outline-none text-white bg-blue-600"
                inactiveProps={{
                  className:
                    "text-[#3A3A3C] text-zinc-800 dark:text-zinc-100 bg-transparent",
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
