import Cocoa

struct WindowAsSheetSendablePointers: Sendable {
    let parentAddress: Int
    let childAddress: Int
    var parentRawPointer: OpaquePointer {
        OpaquePointer(bitPattern: parentAddress)!
    }
    var childRawPointer: OpaquePointer {
        OpaquePointer(bitPattern: childAddress)!
    }

}

@MainActor

class WindowAsSheetManager: NSObject {
    static let shared = WindowAsSheetManager()
    private var activeSheetWindow: NSWindow?
    private var currentParentWindow: NSWindow?
    private var currentChildSourceWindow: NSWindow?
    private var stolenView: NSView?

    func showSheet(sendablePtrs: WindowAsSheetSendablePointers, width: Double, height: Double) {
        let parentRaw = UnsafeMutableRawPointer(sendablePtrs.parentRawPointer)
        let childRaw = UnsafeMutableRawPointer(sendablePtrs.childRawPointer)
        let parentWindow = Unmanaged<NSWindow>.fromOpaque(parentRaw).takeUnretainedValue()
        let childSourceWindow = Unmanaged<NSWindow>.fromOpaque(childRaw).takeUnretainedValue()
        if activeSheetWindow != nil { return }
        self.currentParentWindow = parentWindow
        self.currentChildSourceWindow = childSourceWindow

        guard let targetView = childSourceWindow.contentView else { return }

        self.stolenView = targetView

        let placeholder = NSView()

        childSourceWindow.contentView = placeholder

        childSourceWindow.orderOut(nil)

        let sheetContentRect = NSRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))

        let sheetWindow = NSWindow(
            contentRect: sheetContentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        sheetWindow.isOpaque = false
        sheetWindow.backgroundColor = .clear
        let visualEffectView = NSVisualEffectView(frame: sheetContentRect)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.addSubview(targetView)

        targetView.frame = visualEffectView.bounds
        targetView.autoresizingMask = [.width, .height]

        sheetWindow.contentView = visualEffectView

        self.activeSheetWindow = sheetWindow

        parentWindow.beginSheet(sheetWindow) { response in
            MainActor.assumeIsolated {
                self.cleanupSheetState()
            }
        }

        window_as_modal_sheet_event(.Opened)

    }

    func closeSheet() {
        guard let parent = currentParentWindow, let sheet = activeSheetWindow else { return }
        parent.endSheet(sheet)

    }

    private func cleanupSheetState() {
        if let sourceWindow = currentChildSourceWindow, let originalView = stolenView {
            sourceWindow.contentView = originalView
        }

        self.activeSheetWindow = nil
        self.currentParentWindow = nil
        self.currentChildSourceWindow = nil
        self.stolenView = nil

        window_as_modal_sheet_event(.Closed)

    }

}

public func showWindowAsModalSheet(
    parentWindowRawPtr: UnsafeMutableRawPointer?, childWindowRawPtr: UnsafeMutableRawPointer?,
    width: Double, height: Double
) {
    let parentInt = Int(bitPattern: parentWindowRawPtr)
    let childInt = Int(bitPattern: childWindowRawPtr)
    let sendableContainer = WindowAsSheetSendablePointers(
        parentAddress: parentInt, childAddress: childInt)

    DispatchQueue.main.async {
        WindowAsSheetManager.shared.showSheet(
            sendablePtrs: sendableContainer, width: width, height: height)

    }

}

public func closeWindowAsModalSheet() {
    DispatchQueue.main.async {
        WindowAsSheetManager.shared.closeSheet()

    }

}
