import Cocoa

struct WindowAsPanelSendableWindowPointer: Sendable {
    let address: Int

    var rawPointer: OpaquePointer {
        OpaquePointer(bitPattern: address)!
    }
}

@MainActor
private final class WindowAsPanelInstanceContainer {
    let panel: HoverResponsivePanel
    weak var sourceWindow: NSWindow?
    var trackingArea: NSTrackingArea?
    var originalWebviewSize: NSSize?
    var currentPanelOrigin: NSPoint?
    var moveObserver: NSObjectProtocol?

    init(
        panel: HoverResponsivePanel, sourceWindow: NSWindow? = nil,
        trackingArea: NSTrackingArea? = nil
    ) {
        self.panel = panel
        self.sourceWindow = sourceWindow
        self.trackingArea = trackingArea
    }
}

@MainActor
private final class WindowAsPanelPanelStorage {
    static var activePanels: [String: WindowAsPanelInstanceContainer] = [:]
    static var isCleaningUp = false
}

class HoverResponsivePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsMouseMovedEvents: Bool {
        get { return true }
        set {}
    }
}

class WindowAsPanelSwiftDragHandleView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let pillWidth: CGFloat = 40.0
        let pillHeight: CGFloat = 4.0

        let pillRect = NSRect(
            x: (bounds.width - pillWidth) / 2.0,
            y: (bounds.height - pillHeight) / 2.0,
            width: pillWidth,
            height: pillHeight
        )

        let path = NSBezierPath(roundedRect: pillRect, xRadius: 2.0, yRadius: 2.0)
        NSColor.secondaryLabelColor.withAlphaComponent(0.4).set()
        path.fill()
    }

    override func mouseDown(with event: NSEvent) {
        guard let window = self.window else {
            super.mouseDown(with: event)
            return
        }

        window.performDrag(with: event)

        if let panel = window as? HoverResponsivePanel {
            MainActor.assumeIsolated {
                if let activeContainer = WindowAsPanelPanelStorage.activePanels.values.first(
                    where: { $0.panel == panel })
                {
                    activeContainer.currentPanelOrigin = panel.frame.origin
                }
            }
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }
}

@MainActor
class WindowAsPanelManager {
    static let shared = WindowAsPanelManager()
    static let dragHandleHeight: CGFloat = 16.0
    static let cornerRadius: CGFloat = 20.0

    private func getOrCreatePanel(for id: String, showOnAllSpaces: Bool, alwaysOnTop: Bool)
        -> HoverResponsivePanel
    {
        if let container = WindowAsPanelPanelStorage.activePanels[id] {
            if showOnAllSpaces {
                container.panel.collectionBehavior =
                    alwaysOnTop
                    ? [.canJoinAllSpaces, .ignoresCycle, .stationary]
                    : [.canJoinAllSpaces, .ignoresCycle]
            } else {
                container.panel.collectionBehavior =
                    alwaysOnTop
                    ? [.moveToActiveSpace, .ignoresCycle, .stationary]
                    : [.moveToActiveSpace, .ignoresCycle]
            }

            container.panel.level = alwaysOnTop ? .statusBar : .normal

            return container.panel
        }

        let panel = HoverResponsivePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        panel.level = alwaysOnTop ? .statusBar : .normal

        if showOnAllSpaces {
            panel.collectionBehavior =
                alwaysOnTop
                ? [
                    .canJoinAllSpaces,
                    .ignoresCycle,
                    .stationary,
                ]
                : [
                    .canJoinAllSpaces,
                    .ignoresCycle,
                ]
        } else {
            panel.collectionBehavior =
                alwaysOnTop
                ? [
                    .moveToActiveSpace,
                    .ignoresCycle,
                    .stationary,
                ]
                : [
                    .moveToActiveSpace,
                    .ignoresCycle,
                ]
        }

        let newContainer = WindowAsPanelInstanceContainer(panel: panel)
        WindowAsPanelPanelStorage.activePanels[id] = newContainer
        return panel
    }

    func show(
        id: String, sendablePtr: WindowAsPanelSendableWindowPointer, x: Double, y: Double,
        showOnAllSpaces: Bool = false, alwaysOnTop: Bool = false, liquidGlassEffect: Bool = false,
    ) {
        let containerExists = WindowAsPanelPanelStorage.activePanels[id] != nil
        var cachedSize: NSSize? = nil
        var trackedOrigin: NSPoint? = nil

        if containerExists {
            cachedSize = WindowAsPanelPanelStorage.activePanels[id]?.originalWebviewSize
            trackedOrigin = WindowAsPanelPanelStorage.activePanels[id]?.currentPanelOrigin
            clearPanelContents(for: id)
        }

        let panel = getOrCreatePanel(
            for: id, showOnAllSpaces: showOnAllSpaces, alwaysOnTop: alwaysOnTop)
        let rawUnsafe = UnsafeMutableRawPointer(sendablePtr.rawPointer)

        let sourceWindow = Unmanaged<NSWindow>.fromOpaque(rawUnsafe).takeUnretainedValue()

        guard let stolenView = sourceWindow.contentView else { return }

        if let parent = sourceWindow.parent {
            parent.removeChildWindow(sourceWindow)
        }

        let placeholder = NSView(frame: stolenView.frame)
        sourceWindow.contentView = placeholder
        sourceWindow.orderOut(nil)

        let targetSize: NSSize = cachedSize ?? sourceWindow.frame.size

        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        container.sourceWindow = sourceWindow
        container.originalWebviewSize = targetSize

        if container.moveObserver == nil {
            container.moveObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: panel,
                queue: .main
            ) { [weak container] _ in
                Task { @MainActor [weak container] in
                    guard let container = container else { return }

                    container.currentPanelOrigin = container.panel.frame.origin

                    if let sourceWindow = container.sourceWindow {
                        let currentPanelFrame = container.panel.frame
                        sourceWindow.setFrame(
                            NSRect(
                                x: currentPanelFrame.origin.x,
                                y: currentPanelFrame.origin.y,
                                width: currentPanelFrame.width,
                                height: currentPanelFrame.height
                            ),
                            display: true
                        )
                    }
                }
            }
        }

        let containerView = NSView(frame: NSRect(origin: .zero, size: targetSize))
        containerView.autoresizingMask = [.width, .height]

        let effectView: NSView
        let glassCanvas = NSView(frame: containerView.bounds)
        glassCanvas.autoresizingMask = [.width, .height]

        if liquidGlassEffect, #available(macOS 26.0, *) {
            let glassEffectView = NSGlassEffectView()
            glassEffectView.frame = containerView.bounds
            glassEffectView.autoresizingMask = [.width, .height]
            glassEffectView.cornerRadius = Self.cornerRadius

            glassEffectView.setValue(9, forKey: "variant")
            glassEffectView.setValue(0, forKey: "scrimState")
            glassEffectView.setValue(1, forKey: "subduedState")

            glassEffectView.contentView = glassCanvas
            effectView = glassEffectView
        } else {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.frame = containerView.bounds
            visualEffectView.autoresizingMask = [.width, .height]

            visualEffectView.wantsLayer = true
            visualEffectView.layer?.masksToBounds = true
            visualEffectView.layer?.cornerRadius = Self.cornerRadius

            visualEffectView.material = .popover
            visualEffectView.blendingMode = .withinWindow
            visualEffectView.state = .active

            visualEffectView.addSubview(glassCanvas)
            effectView = visualEffectView
        }

        stolenView.frame = glassCanvas.bounds
        stolenView.autoresizingMask = [.width, .height]
        stolenView.wantsLayer = true
        stolenView.layer?.backgroundColor = NSColor.clear.cgColor
        glassCanvas.addSubview(stolenView)

        let dragHandle = WindowAsPanelSwiftDragHandleView()
        dragHandle.frame = NSRect(
            x: 0, y: targetSize.height - Self.dragHandleHeight, width: targetSize.width,
            height: Self.dragHandleHeight)
        dragHandle.autoresizingMask = [.width, .minYMargin]
        glassCanvas.addSubview(dragHandle)

        containerView.addSubview(effectView)
        panel.contentView = containerView

        if let dynamicPos = trackedOrigin {
            panel.setFrame(
                NSRect(origin: dynamicPos, size: targetSize), display: true, animate: false)
            container.currentPanelOrigin = dynamicPos
        } else {
            guard let primaryScreen = sourceWindow.screen ?? NSScreen.main else { return }
            let screenFrame = primaryScreen.frame

            let panelX = screenFrame.origin.x + CGFloat(x)
            let panelY =
                screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height

            let panelRect = NSRect(origin: NSPoint(x: panelX, y: panelY), size: targetSize)
            panel.setFrame(panelRect, display: true, animate: false)
            container.currentPanelOrigin = panelRect.origin
        }

        sourceWindow.styleMask = [.borderless]
        sourceWindow.isOpaque = false
        sourceWindow.backgroundColor = .clear
        sourceWindow.hasShadow = false

        sourceWindow.setFrame(
            NSRect(
                x: panel.frame.origin.x, y: panel.frame.origin.y, width: targetSize.width,
                height: targetSize.height), display: true)
        panel.addChildWindow(sourceWindow, ordered: .below)

        panel.orderFrontRegardless()
        panel.makeKey()
        panel.invalidateShadow()

        let trackingArea = NSTrackingArea(
            rect: containerView.bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: containerView,
            userInfo: nil
        )
        containerView.addTrackingArea(trackingArea)
        container.trackingArea = trackingArea

        WindowAsPanelPanelStorage.isCleaningUp = false
        window_as_panel_event(.Opened(panel_id: RustString(id)))
    }

    func resizePanel(
        id: String, width: Double, height: Double, animate: Bool = false,
        blurOverlayOnResize: Bool = false
    ) {
        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        let panel = container.panel
        guard let contentView = panel.contentView else { return }

        let newSize = NSSize(width: CGFloat(width), height: CGFloat(height))

        if abs(panel.frame.width - newSize.width) < 0.1
            && abs(panel.frame.height - newSize.height) < 0.1
        {
            return
        }

        container.originalWebviewSize = newSize

        let currentFrame = panel.frame
        let centerX = currentFrame.origin.x + (currentFrame.width / 2.0)
        let centerY = currentFrame.origin.y + (currentFrame.height / 2.0)

        let newX = centerX - (newSize.width / 2.0)
        let newY = centerY - (newSize.height / 2.0)

        let newPanelRect = NSRect(x: newX, y: newY, width: newSize.width, height: newSize.height)
        let newSourceWindowRect = newPanelRect

        container.currentPanelOrigin = newPanelRect.origin

        var temporaryBlur: NSVisualEffectView? = nil
        if blurOverlayOnResize {
            let blur = NSVisualEffectView(frame: contentView.bounds)
            blur.identifier = NSUserInterfaceItemIdentifier("WindowAsPanel.TemporaryBlurOverlay")
            blur.autoresizingMask = [.width, .height]
            blur.material = .sidebar
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.alphaValue = 1.0

            blur.wantsLayer = true
            blur.layer?.cornerRadius = Self.cornerRadius
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

                    panel.animator().setFrame(newPanelRect, display: true)
                    container.sourceWindow?.animator().setFrame(newSourceWindowRect, display: true)
                } else {
                    panel.setFrame(newPanelRect, display: true)
                    container.sourceWindow?.setFrame(newSourceWindowRect, display: true)
                }
            },
            completionHandler: {
                Task { @MainActor [stableBlurReference] in
                    contentView.needsDisplay = true
                    panel.contentView?.needsDisplay = true

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

    func movePanel(id: String, x: Double, y: Double) {
        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        let panel = container.panel

        guard let primaryScreen = panel.screen ?? NSScreen.main else { return }
        let screenFrame = primaryScreen.frame
        let targetSize = panel.frame.size

        let panelX = screenFrame.origin.x + CGFloat(x)
        let panelY =
            screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height

        let panelRect = NSRect(origin: NSPoint(x: panelX, y: panelY), size: targetSize)
        panel.setFrame(panelRect, display: true, animate: false)

        container.currentPanelOrigin = panelRect.origin

        if let sourceWindow = container.sourceWindow {
            sourceWindow.setFrame(
                NSRect(
                    x: panelX, y: panelY, width: targetSize.width,
                    height: targetSize.height), display: true)
        }
    }

    private func clearPanelContents(for id: String) {
        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        let panel = container.panel

        if let observer = container.moveObserver {
            NotificationCenter.default.removeObserver(observer)
            container.moveObserver = nil
        }

        if let sourceWindow = container.sourceWindow {
            if let content = panel.contentView {
                let foundEffectView = content.subviews.first { subview in
                    if subview.identifier?.rawValue == "WindowAsPanel.TemporaryBlurOverlay" {
                        return false
                    }
                    if #available(macOS 26.0, *), subview.isKind(of: NSGlassEffectView.self) {
                        return true
                    }
                    return subview.isKind(of: NSVisualEffectView.self)
                }

                if let effectView = foundEffectView {
                    let internalCanvas: NSView?
                    if #available(macOS 26.0, *), effectView is NSGlassEffectView {
                        internalCanvas = (effectView as? NSGlassEffectView)?.contentView
                    } else {
                        internalCanvas = effectView.subviews.first {
                            !$0.isKind(of: NSVisualEffectView.self)
                        }
                    }

                    if let canvas = internalCanvas,
                        let stolenView = canvas.subviews.first(where: {
                            !$0.isKind(of: WindowAsPanelSwiftDragHandleView.self)
                        })
                    {
                        stolenView.removeFromSuperview()
                        sourceWindow.contentView = stolenView
                    }
                }
            }
            panel.removeChildWindow(sourceWindow)
            sourceWindow.orderOut(nil)
        }

        if let content = panel.contentView {
            if let tracking = container.trackingArea {
                content.removeTrackingArea(tracking)
                container.trackingArea = nil
            }

            for subview in content.subviews {
                subview.removeFromSuperview()
            }
        }
        panel.contentView = nil
    }

    func closePanel(id: String) {
        guard !WindowAsPanelPanelStorage.isCleaningUp,
            let container = WindowAsPanelPanelStorage.activePanels[id],
            container.panel.isVisible
        else { return }

        WindowAsPanelPanelStorage.isCleaningUp = true

        let panel = container.panel
        panel.orderOut(nil)

        clearPanelContents(for: id)

        WindowAsPanelPanelStorage.activePanels.removeValue(forKey: id)
        WindowAsPanelPanelStorage.isCleaningUp = false

        window_as_panel_event(.Closed(panel_id: RustString(id)))
    }
}

public func showWindowAsPanel(
    id: RustString, windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double,
    showOnAllSpaces: Bool = false, alwaysOnTop: Bool = false, liquidGlassEffect: Bool = false
) {
    let idStr = id.toString()
    let ptrInt = Int(bitPattern: windowRawPtr)
    let sendableContainer = WindowAsPanelSendableWindowPointer(address: ptrInt)

    DispatchQueue.main.async {
        WindowAsPanelManager.shared.show(
            id: idStr, sendablePtr: sendableContainer, x: x, y: y,
            showOnAllSpaces: showOnAllSpaces, alwaysOnTop: alwaysOnTop,
            liquidGlassEffect: liquidGlassEffect, )
    }
}

public func moveWindowAsPanel(id: RustString, x: Double, y: Double) {
    let idStr = id.toString()
    DispatchQueue.main.async {
        WindowAsPanelManager.shared.movePanel(id: idStr, x: x, y: y)
    }
}

public func resizeWindowAsPanel(
    id: RustString, width: Double, height: Double, animate: Bool = false,
    blurOverlayOnResize: Bool = false
) {
    let idStr = id.toString()
    DispatchQueue.main.async {
        WindowAsPanelManager.shared.resizePanel(
            id: idStr, width: width, height: height, animate: animate,
            blurOverlayOnResize: blurOverlayOnResize)
    }
}

public func closeWindowAsPanel(id: RustString) {
    let idStr = id.toString()

    DispatchQueue.main.async {
        WindowAsPanelManager.shared.closePanel(id: idStr)
    }
}

public func isWindowAsPanelVisible(id: RustString) -> Bool {
    let idStr = id.toString()

    if Thread.isMainThread {
        return MainActor.assumeIsolated {
            WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
        }
    } else {
        return DispatchQueue.main.sync {
            return MainActor.assumeIsolated {
                WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
            }
        }
    }
}
