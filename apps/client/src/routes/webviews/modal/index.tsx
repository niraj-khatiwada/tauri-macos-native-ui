import { invoke } from "@tauri-apps/api/core";
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/webviews/modal/")({
  component: ModalWindow,
});

export default function ModalWindow() {
  const handleCloseModal = () => {
    invoke("close_window_as_modal_sheet");
  };

  return (
    <>
      <div className="p-4 w-screen h-screen my-4 overflow-auto">
        <h1 className="text-2xl text-center text-white">Modal</h1>

        <p className="text-white mt-10">
          This modal goes beyond the window boundaries. They are fixed relative
          to parent window. Try moving parent window, this will move seamlessly
          as well
        </p>
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
