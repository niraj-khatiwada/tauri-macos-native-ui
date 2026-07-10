import { createFileRoute } from "@tanstack/react-router";
import { Sidebar } from "./Sidebar";

export const Route = createFileRoute("/(root)/")({
  component: App,
});

function App() {
  return (
    <section className="grid grid-cols-[200px_1fr]">
      <Sidebar />
      <div />
    </section>
  );
}
