import React from "react";

import ChatBubble from "~/assets/icons/chat-bubble.svg?react";
import Rectangle from "~/assets/icons/rectangle.svg?react";
import Toast from "~/assets/icons/toast.svg?react";
import AI from "~/assets/icons/ai.svg?react";

type SVGAsComponent = React.FunctionComponent<React.SVGProps<SVGSVGElement>>;

function asRegistry<T extends string>(
  arg: Record<T, SVGAsComponent>,
): Record<T, SVGAsComponent> {
  return arg;
}

const registry = asRegistry({
  "chat-bubble": ChatBubble,
  rectangle: Rectangle,
  toast: Toast,
  ai: AI,
});

export default registry;
