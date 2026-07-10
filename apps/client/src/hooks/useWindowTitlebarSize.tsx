import { useQuery } from "@tanstack/react-query";
import { getWindowTitlebarSize } from "~/tauri/utils";

export function useTitlebarSize() {
  const { data: windowTitlebarSize } = useQuery({
    queryKey: ["windowTitlebarSize"],
    queryFn: getWindowTitlebarSize,
  });

  return windowTitlebarSize?.logical?.height ?? 0;
}
