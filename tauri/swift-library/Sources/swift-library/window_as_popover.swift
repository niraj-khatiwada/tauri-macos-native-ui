import Cocoa

struct WindowAsPopoverSendableWindowPointer: Sendable {
    let address: Int

    var rawPointer: OpaquePointer {
        OpaquePointer(bitPattern: address)!
    }
}

@MainActor
class WindowAsPopoverManager: NSObject, NSPopoverDelegate {
    static let shared = WindowAsPopoverManager()

    public var activePopover: NSPopover?
    private var currentSourceWindow: NSWindow?
    private var isCleaningUp = false
    
    public var isHigherLayerActive = false

    private lazy var sharedAnchorWindow: NSWindow = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.alphaValue = 0.0
        window.ignoresMouseEvents = true
        window.level = .mainMenu + 1
        return window
    }()

    func show(sendablePtr: WindowAsPopoverSendableWindowPointer, x: Double, y: Double) {
        self.stopObservingGlobalEvents()
        
        if self.activePopover != nil {
            self.closeActivePopover()
        }

        let rawUnsafe = UnsafeMutableRawPointer(sendablePtr.rawPointer)
        let sourceWindow = Unmanaged<NSWindow>.fromOpaque(rawUnsafe).takeUnretainedValue()
        
        self.currentSourceWindow = sourceWindow

        guard let stolenView = sourceWindow.contentView else { return }
        stolenView.wantsLayer = true
        stolenView.layer?.backgroundColor = NSColor.clear.cgColor

        let placeholder = NSView()
        sourceWindow.contentView = placeholder
        sourceWindow.orderOut(nil)

        guard let primaryScreen = sourceWindow.screen ?? NSScreen.main else { return }
        let screenFrame = primaryScreen.frame
        let targetSize = sourceWindow.frame.size

        let windowFrameHeight = sourceWindow.frame.height
        let contentBoundsHeight = stolenView.bounds.height
        let titlebarHeight = windowFrameHeight - contentBoundsHeight

        let anchorX = screenFrame.origin.x + CGFloat(x)
        let anchorY = screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - titlebarHeight

        let targetRect = NSRect(x: anchorX, y: anchorY, width: 1.0, height: 1.0)
        sharedAnchorWindow.setFrame(targetRect, display: true)
        sharedAnchorWindow.orderFrontRegardless()

        let controller = NSViewController()
        controller.view = stolenView

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = controller
        popover.contentSize = targetSize
        popover.delegate = self

        if let dummyView = sharedAnchorWindow.contentView {
            popover.show(relativeTo: dummyView.bounds, of: dummyView, preferredEdge: .minY)
        }

        self.activePopover = popover
        self.isCleaningUp = false

        window_as_popover_event(WindowAsPopoverEventType.Opened)  // notify rust

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalDismissal(_:)),
            name: NSWindow.didMoveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalDismissal(_:)),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
    }

    @objc private func handleGlobalDismissal(_ notification: Notification) {
        guard !isCleaningUp else { return }
        if isHigherLayerActive { return }

        if let window = notification.object as? NSWindow {
            if window == sharedAnchorWindow {
                return
            }
        }

        closeActivePopover()
    }

    func closeActivePopover() {
        guard !isCleaningUp else { return }
        isCleaningUp = true

        self.stopObservingGlobalEvents()

        if let popover = activePopover {
            popover.close()
        }
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                let manager = WindowAsPopoverManager.shared
                
                if let sourceWindow = manager.currentSourceWindow,
                   let popover = manager.activePopover,
                   let controller = popover.contentViewController {
                    let stolenView = controller.view
                    sourceWindow.contentView = stolenView
                }
                
                manager.sharedAnchorWindow.orderOut(nil)
                manager.activePopover = nil
                manager.currentSourceWindow = nil
                manager.isCleaningUp = false

                window_as_popover_event(WindowAsPopoverEventType.Closed)  // notify rust
            }
        }
    }

    func isPopoverOpened() -> Bool {
        return activePopover?.isShown ?? false
    }

    private func stopObservingGlobalEvents() {
        NotificationCenter.default.removeObserver(
            self, name: NSWindow.didMoveNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: NSWindow.didResignKeyNotification, object: nil)
    }
}

public func showWindowAsPopover(windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double) {
    let ptrInt = Int(bitPattern: windowRawPtr)
    let sendableContainer = WindowAsPopoverSendableWindowPointer(address: ptrInt)

    DispatchQueue.main.async {
        WindowAsPopoverManager.shared.show(sendablePtr: sendableContainer, x: x, y: y)
    }
}

public func closeWindowAsPopover() {
    DispatchQueue.main.async {
        WindowAsPopoverManager.shared.closeActivePopover()
    }
}

public func isWindowAsPopoverVisible() -> Bool {
    if Thread.isMainThread {
        return MainActor.assumeIsolated { WindowAsPopoverManager.shared.isPopoverOpened() }
    } else {
        return DispatchQueue.main.sync {
            return MainActor.assumeIsolated { WindowAsPopoverManager.shared.isPopoverOpened() }
        }
    }
}
