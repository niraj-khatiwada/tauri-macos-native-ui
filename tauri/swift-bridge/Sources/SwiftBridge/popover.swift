import Cocoa
import SwiftRs

class PopoverContentViewController: NSViewController {
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))

        let label = NSTextField(labelWithString: "⌥ + ⌘ + E")
        label.frame = NSRect(x: 50, y: 40, width: 100, height: 20)
        self.view.addSubview(label)
    }
}

@_cdecl("show_native_popover")
public func showNativePopover(windowPtr: UnsafeRawPointer, x: Double, y: Double) {
    let windowAddress = Int(bitPattern: windowPtr)

    DispatchQueue.main.async {
        guard let safePtr = UnsafeRawPointer(bitPattern: windowAddress) else { return }
        let parentWindow = Unmanaged<NSWindow>.fromOpaque(safePtr).takeUnretainedValue()
        guard let parentContentView = parentWindow.contentView else { return }

        let windowHeight = parentContentView.bounds.height
        let adjustedY = windowHeight - CGFloat(y)
        let adjustedX = CGFloat(x)

        let targetRect = NSRect(x: adjustedX, y: adjustedY, width: 1, height: 1)

        let popover = NSPopover()
        popover.contentViewController = PopoverContentViewController()
        popover.behavior = .transient
        popover.animates = true

        popover.show(
            relativeTo: targetRect,
            of: parentContentView,
            preferredEdge: .minY
        )
    }
}
