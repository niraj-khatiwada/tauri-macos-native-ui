import {
  createHashHistory,
  createRouter,
  RouterProvider,
} from "@tanstack/react-router";

import ReactDOM from "react-dom/client";
import "./styles.css";

import { routeTree } from "./routeTree.gen";

// See `vite.config.ts` for all defined values.
window.__appVersion = __appVersion;
window.__envMode = __envMode;

const hashHistory = createHashHistory();

const router = createRouter({
  routeTree,
  defaultPreload: "intent",
  history: hashHistory,
});

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}

let base = <RouterProvider router={router} />;

const rootElement = document.getElementById("app")!;
if (!rootElement.innerHTML) {
  const root = ReactDOM.createRoot(rootElement);
  root.render(base);
}
