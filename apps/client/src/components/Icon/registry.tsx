import React from "react";

import ChatBubble from "~/assets/icons/chat-bubble.svg?react";
import Rectangle from "~/assets/icons/rectangle.svg?react";
import Toast from "~/assets/icons/toast.svg?react";
import AI from "~/assets/icons/ai.svg?react";
import Bell from "~/assets/icons/bell.svg?react";
import Menu from "~/assets/icons/menu.svg?react";
import Home from "~/assets/icons/home.svg?react";

type SVGAsComponent = React.FunctionComponent<React.SVGProps<SVGSVGElement>>;

function asRegistry<T extends string>(
  arg: Record<T, SVGAsComponent>,
): Record<T, SVGAsComponent> {
  return arg;
}

const registry = asRegistry({
  home: Home,
  "chat-bubble": ChatBubble,
  rectangle: Rectangle,
  toast: Toast,
  ai: AI,
  bell: Bell,
  menu: Menu,
});

export default registry;
