import { invoke } from "@tauri-apps/api/core";
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/webviews/modal/")({
  component: ModalWindow,
});

export default function ModalWindow() {
  const handleCloseModal = () => {
    invoke("close_window_as_modal_sheet");
  };

  const handleResize = () => {
    invoke("resize_window_as_modal_sheet", {
      width: Math.max(200, Math.random() * 1000),
      height: Math.max(200, Math.random() * 1000),
      animate: true,
      blurOverlayOnResize: true,
    });
  };

  return (
    <>
      <div className="relative p-4 w-screen h-screen overflow-auto">
        <h1 className="text-2xl text-center text-white">Modal</h1>
        <p className="text-white mt-10">
          This modal goes beyond the window boundaries. They are fixed relative
          to parent window. Try moving parent window, this will move seamlessly
          as well
        </p>
        <div className="w-full flex justify-center">
          <button
            onClick={handleResize}
            className="bg-blue-600 px-4 py-1 text-white rounded-md text-xs w-fit mx-auto mt-10"
          >
            Resize
          </button>
        </div>
        <button
          onClick={handleCloseModal}
          className="bg-blue-600 px-4 py-1 rounded-md text-xs w-fit text-white absolute bottom-4 right-4"
        >
          Close Modal
        </button>
      </div>
    </>
  );
}
