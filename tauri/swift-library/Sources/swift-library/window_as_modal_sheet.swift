import Cocoa

struct WindowAsModalSendablePointers: Sendable {
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
class WindowAsModalManager: NSObject {
    static let shared = WindowAsModalManager()
    private var activeSheetWindow: NSWindow?
    private var currentParentWindow: NSWindow?
    private var currentChildSourceWindow: NSWindow?
    private var stolenView: NSView?

    func showSheet(sendablePtrs: WindowAsModalSendablePointers, width: Double, height: Double) {
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

    func resizeSheet(
        width: Double, height: Double, animate: Bool = false,
        blurOverlayOnResize: Bool = false
    ) {
        guard let sheet = activeSheetWindow, let contentView = sheet.contentView else { return }

        let newSize = NSSize(width: CGFloat(width), height: CGFloat(height))

        if abs(sheet.frame.width - newSize.width) < 0.1
            && abs(sheet.frame.height - newSize.height) < 0.1
        {
            return
        }

        let currentFrame = sheet.frame
        let centerX = currentFrame.origin.x + (currentFrame.width / 2.0)
        let centerY = currentFrame.origin.y + (currentFrame.height / 2.0)

        let newX = centerX - (newSize.width / 2.0)
        let newY = centerY - (newSize.height / 2.0)

        let newSheetRect = NSRect(x: newX, y: newY, width: newSize.width, height: newSize.height)

        let sourceOrigin = currentChildSourceWindow?.frame.origin ?? .zero
        let newSourceWindowRect = NSRect(origin: sourceOrigin, size: newSize)

        var temporaryBlur: NSVisualEffectView? = nil
        if blurOverlayOnResize {
            let blur = NSVisualEffectView(frame: contentView.bounds)
            blur.identifier = NSUserInterfaceItemIdentifier("WindowAsModal.TemporaryBlurOverlay")
            blur.autoresizingMask = [.width, .height]
            blur.material = .sidebar
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.alphaValue = 1.0

            blur.wantsLayer = true
            blur.layer?.cornerRadius = 20.0
            blur.layer?.masksToBounds = true

            contentView.addSubview(blur, positioned: .above, relativeTo: nil)
            temporaryBlur = blur
        }

        let stableBlurReference = temporaryBlur
        let duration = animate ? 0.45 : 0.0

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = duration

                if animate {
                    context.timingFunction = CAMediaTimingFunction(
                        controlPoints: 0.25, 1.0, 0.4, 1.15)
                    sheet.animator().setFrame(newSheetRect, display: true)
                    currentChildSourceWindow?.animator().setFrame(
                        newSourceWindowRect, display: true)
                } else {
                    sheet.setFrame(newSheetRect, display: true)
                    currentChildSourceWindow?.setFrame(newSourceWindowRect, display: true)
                }
            },
            completionHandler: {
                Task { @MainActor [stableBlurReference] in
                    contentView.needsDisplay = true
                    sheet.contentView?.needsDisplay = true

                    if let blur = stableBlurReference {
                        try? await Task.sleep(nanoseconds: 50_000_000)

                        NSAnimationContext.runAnimationGroup(
                            { context in
                                context.duration = 0.15
                                blur.animator().alphaValue = 0.0
                            },
                            completionHandler: {
                                Task { @MainActor [blur] in
                                    blur.removeFromSuperview()
                                }
                            })
                    }
                }
            })
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
    let sendableContainer = WindowAsModalSendablePointers(
        parentAddress: parentInt, childAddress: childInt)

    DispatchQueue.main.async {
        WindowAsModalManager.shared.showSheet(
            sendablePtrs: sendableContainer, width: width, height: height)
    }
}

public func resizeWindowAsModalSheet(
    width: Double, height: Double, animate: Bool = false,
    blurOverlayOnResize: Bool = false
) {
    DispatchQueue.main.async {
        WindowAsModalManager.shared.resizeSheet(
            width: width, height: height, animate: animate,
            blurOverlayOnResize: blurOverlayOnResize)
    }
}

public func closeWindowAsModalSheet() {
    DispatchQueue.main.async {
        WindowAsModalManager.shared.closeSheet()
    }
}
