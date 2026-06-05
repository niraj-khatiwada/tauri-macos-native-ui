// import Cocoa

// struct WindowAsPanelSendableWindowPointer: Sendable {
//     let address: Int

//     var rawPointer: OpaquePointer {
//         OpaquePointer(bitPattern: address)!
//     }
// }

// @MainActor
// private final class PanelInstanceContainer {
//     let panel: WindowAsPanelHoverResponsivePanel
//     weak var sourceWindow: NSWindow?
//     var trackingArea: NSTrackingArea?

//     init(
//         panel: WindowAsPanelHoverResponsivePanel, sourceWindow: NSWindow? = nil,
//         trackingArea: NSTrackingArea? = nil
//     ) {
//         self.panel = panel
//         self.sourceWindow = sourceWindow
//         self.trackingArea = trackingArea
//     }
// }

// @MainActor
// private final class WindowAsPanelPanelStorage {
//     static var activePanels: [String: PanelInstanceContainer] = [:]
//     static var isCleaningUp = false
// }

// class WindowAsPanelHoverResponsivePanel: NSPanel {
//     override var canBecomeKey: Bool {
//         return true
//     }

//     override var acceptsMouseMovedEvents: Bool {
//         get { return true }
//         set {}
//     }
// }

// class WindowAsPanelSwiftDragHandleView: NSView {
//     override func draw(_ dirtyRect: NSRect) {
//         super.draw(dirtyRect)

//         let pillWidth: CGFloat = 40.0
//         let pillHeight: CGFloat = 4.0

//         let pillRect = NSRect(
//             x: (bounds.width - pillWidth) / 2.0,
//             y: (bounds.height - pillHeight) / 2.0,
//             width: pillWidth,
//             height: pillHeight
//         )

//         let path = NSBezierPath(roundedRect: pillRect, xRadius: 2.0, yRadius: 2.0)
//         NSColor.secondaryLabelColor.withAlphaComponent(0.4).set()
//         path.fill()
//     }

//     override func mouseDown(with event: NSEvent) {
//         if let window = self.window {
//             if let parentPanel = window.parent as? NSPanel {
//                 parentPanel.performDrag(with: event)
//             } else {
//                 window.performDrag(with: event)
//             }
//         } else {
//             super.mouseDown(with: event)
//         }
//     }

//     override func resetCursorRects() {
//         super.resetCursorRects()
//         addCursorRect(bounds, cursor: .openHand)
//     }
// }

// @MainActor
// class WindowAsPanelManager {
//     static let shared = WindowAsPanelManager()

//     private func getOrCreatePanel(for id: String) -> WindowAsPanelHoverResponsivePanel {
//         if let container = WindowAsPanelPanelStorage.activePanels[id] {
//             return container.panel
//         }

//         let panel = WindowAsPanelHoverResponsivePanel(
//             contentRect: .zero,
//             styleMask: [.borderless, .nonactivatingPanel],
//             backing: .buffered,
//             defer: false
//         )

//         panel.isOpaque = false
//         panel.backgroundColor = .clear
//         panel.hasShadow = true
//         panel.ignoresMouseEvents = false
//         panel.isReleasedWhenClosed = false
//         panel.isMovableByWindowBackground = false

//         panel.hidesOnDeactivate = false
//         panel.level = .statusBar

//         panel.collectionBehavior = [
//             .canJoinAllSpaces,
//             .ignoresCycle,
//             .stationary,
//         ]

//         let newContainer = PanelInstanceContainer(panel: panel)
//         WindowAsPanelPanelStorage.activePanels[id] = newContainer
//         return panel
//     }

//     func show(id: String, sendablePtr: WindowAsPanelSendableWindowPointer, x: Double, y: Double) {
//         if WindowAsPanelPanelStorage.activePanels[id] != nil {
//             clearPanelContents(for: id)
//         }

//         let panel = getOrCreatePanel(for: id)

//         let rawUnsafe = UnsafeMutableRawPointer(sendablePtr.rawPointer)
//         let sourceWindow = Unmanaged<NSWindow>.fromOpaque(rawUnsafe).takeUnretainedValue()

//         if let parent = sourceWindow.parent {
//             parent.removeChildWindow(sourceWindow)
//         }

//         guard let primaryScreen = sourceWindow.screen ?? NSScreen.main else { return }
//         let screenFrame = primaryScreen.frame
//         let targetSize = sourceWindow.frame.size

//         let panelX = screenFrame.origin.x + CGFloat(x)
//         let panelY =
//             screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height

//         let panelRect = NSRect(origin: NSPoint(x: panelX, y: panelY), size: targetSize)
//         panel.setFrame(panelRect, display: true, animate: false)

//         let customCornerRadius: CGFloat = 20.0

//         let containerView = NSView(frame: NSRect(origin: .zero, size: targetSize))
//         containerView.autoresizingMask = [.width, .height]

//         let visualEffectView = NSVisualEffectView()
//         visualEffectView.frame = containerView.bounds
//         visualEffectView.autoresizingMask = [.width, .height]

//         visualEffectView.wantsLayer = true
//         visualEffectView.layer?.masksToBounds = true
//         visualEffectView.layer?.cornerRadius = customCornerRadius
//         visualEffectView.material = .popover
//         visualEffectView.blendingMode = .withinWindow
//         visualEffectView.state = .active

//         let handleHeight: CGFloat = 16.0
//         let dragHandle = WindowAsPanelSwiftDragHandleView()
//         dragHandle.frame = NSRect(
//             x: 0, y: targetSize.height - handleHeight, width: targetSize.width, height: handleHeight
//         )
//         dragHandle.autoresizingMask = [.width, .minYMargin]
//         visualEffectView.addSubview(dragHandle)

//         containerView.addSubview(visualEffectView)
//         panel.contentView = containerView

//         sourceWindow.styleMask = [.borderless]
//         sourceWindow.isOpaque = false
//         sourceWindow.backgroundColor = .clear
//         sourceWindow.hasShadow = false

//         sourceWindow.setFrame(
//             NSRect(
//                 x: panelX, y: panelY, width: targetSize.width,
//                 height: targetSize.height - handleHeight), display: true)

//         panel.addChildWindow(sourceWindow, ordered: .above)

//         WindowAsPanelPanelStorage.isCleaningUp = false

//         panel.orderFrontRegardless()
//         panel.makeKey()
//         panel.invalidateShadow()

//         let trackingArea = NSTrackingArea(
//             rect: containerView.bounds,
//             options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
//             owner: containerView,
//             userInfo: nil
//         )
//         containerView.addTrackingArea(trackingArea)

//         if let container = WindowAsPanelPanelStorage.activePanels[id] {
//             container.sourceWindow = sourceWindow
//             container.trackingArea = trackingArea
//         }

//         WindowAsPanelPanelStorage.isCleaningUp = false

//         window_as_panel_event(.Opened(panel_id: RustString(id)))  // notify rust
//     }

//     func movePanel(id: String, x: Double, y: Double) {
//         guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
//         let panel = container.panel

//         guard let primaryScreen = panel.screen ?? NSScreen.main else { return }
//         let screenFrame = primaryScreen.frame
//         let targetSize = panel.frame.size

//         let panelX = screenFrame.origin.x + CGFloat(x)
//         let panelY =
//             screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height

//         let panelRect = NSRect(origin: NSPoint(x: panelX, y: panelY), size: targetSize)
//         panel.setFrame(panelRect, display: true, animate: false)

//         if let sourceWindow = container.sourceWindow {
//             let handleHeight: CGFloat = 16.0
//             sourceWindow.setFrame(
//                 NSRect(
//                     x: panelX, y: panelY, width: targetSize.width,
//                     height: targetSize.height - handleHeight), display: true)
//         }
//     }

//     private func clearPanelContents(for id: String) {
//         guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
//         let panel = container.panel

//         if let sourceWindow = container.sourceWindow {
//             panel.removeChildWindow(sourceWindow)
//             sourceWindow.orderOut(nil)
//         }

//         if let content = panel.contentView {
//             if let tracking = container.trackingArea {
//                 content.removeTrackingArea(tracking)
//                 container.trackingArea = nil
//             }
//             for subview in content.subviews {
//                 subview.removeFromSuperview()
//             }
//         }
//         panel.contentView = nil
//     }

//     func closePanel(id: String) {
//         guard !WindowAsPanelPanelStorage.isCleaningUp,
//             let container = WindowAsPanelPanelStorage.activePanels[id],
//             container.panel.isVisible
//         else { return }

//         WindowAsPanelPanelStorage.isCleaningUp = true

//         let panel = container.panel
//         panel.orderOut(nil)

//         clearPanelContents(for: id)

//         WindowAsPanelPanelStorage.activePanels.removeValue(forKey: id)
//         WindowAsPanelPanelStorage.isCleaningUp = false

//         window_as_panel_event(.Closed(panel_id: RustString(id)))  // notify rust

//     }
// }

// public func showWindowAsPanel(
//     id: RustString, windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double
// ) {
//     let idStr = id.toString()
//     let ptrInt = Int(bitPattern: windowRawPtr)
//     let sendableContainer = WindowAsPanelSendableWindowPointer(address: ptrInt)

//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.show(id: idStr, sendablePtr: sendableContainer, x: x, y: y)
//     }
// }

// public func moveWindowAsPanel(id: RustString, x: Double, y: Double) {
//     let idStr = id.toString()
//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.movePanel(id: idStr, x: x, y: y)
//     }
// }

// public func closeWindowAsPanel(id: RustString) {
//     let idStr = id.toString()

//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.closePanel(id: idStr)
//     }
// }

// public func isWindowAsPanelVisible(id: RustString) -> Bool {
//     let idStr = id.toString()

//     if Thread.isMainThread {
//         return MainActor.assumeIsolated {
//             WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
//         }
//     } else {
//         return DispatchQueue.main.sync {
//             return MainActor.assumeIsolated {
//                 WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
//             }
//         }
//     }
// }

// import Cocoa
// import SwiftUI  // Required for the Apple Intelligence glow effect

// struct WindowAsPanelSendableWindowPointer: Sendable {
//     let address: Int

//     var rawPointer: OpaquePointer {
//         OpaquePointer(bitPattern: address)!
//     }
// }

// @MainActor
// private final class PanelInstanceContainer {
//     let panel: WindowAsPanelAIHoverResponsivePanel
//     weak var sourceWindow: NSWindow?
//     var trackingArea: NSTrackingArea?

//     // NEW: We store the actual webview size and glow state to calculate moves correctly
//     var targetSize: NSSize
//     var hasAIGlow: Bool

//     init(
//         panel: WindowAsPanelAIHoverResponsivePanel, sourceWindow: NSWindow? = nil,
//         trackingArea: NSTrackingArea? = nil, targetSize: NSSize = .zero, hasAIGlow: Bool = false
//     ) {
//         self.panel = panel
//         self.sourceWindow = sourceWindow
//         self.trackingArea = trackingArea
//         self.targetSize = targetSize
//         self.hasAIGlow = hasAIGlow
//     }
// }

// @MainActor
// private final class WindowAsPanelPanelStorage {
//     static var activePanels: [String: PanelInstanceContainer] = [:]
//     static var isCleaningUp = false
// }

// class WindowAsPanelAIHoverResponsivePanel: NSPanel {
//     override var canBecomeKey: Bool {
//         return true
//     }

//     override var acceptsMouseMovedEvents: Bool {
//         get { return true }
//         set {}
//     }
// }

// class WindowAsPanelAISwiftDragHandleView: NSView {
//     override func draw(_ dirtyRect: NSRect) {
//         super.draw(dirtyRect)

//         let pillWidth: CGFloat = 40.0
//         let pillHeight: CGFloat = 4.0

//         let pillRect = NSRect(
//             x: (bounds.width - pillWidth) / 2.0,
//             y: (bounds.height - pillHeight) / 2.0,
//             width: pillWidth,
//             height: pillHeight
//         )

//         let path = NSBezierPath(roundedRect: pillRect, xRadius: 2.0, yRadius: 2.0)
//         NSColor.secondaryLabelColor.withAlphaComponent(0.4).set()
//         path.fill()
//     }

//     override func mouseDown(with event: NSEvent) {
//         if let window = self.window {
//             if let parentPanel = window.parent as? NSPanel {
//                 parentPanel.performDrag(with: event)
//             } else {
//                 window.performDrag(with: event)
//             }
//         } else {
//             super.mouseDown(with: event)
//         }
//     }

//     override func resetCursorRects() {
//         super.resetCursorRects()
//         addCursorRect(bounds, cursor: .openHand)
//     }
// }

// // MARK: - SwiftUI Glow Component
// struct AIGlowBackgroundView: View {
//     @State private var phase: CGFloat = 0.0
//     let aiColors = [Color.blue, Color.purple, Color.pink, Color.orange, Color.cyan, Color.blue]
//     let cornerRadius: CGFloat
//     let padding: CGFloat

//     var body: some View {
//         ZStack {
//             // Main Glass body
//             Rectangle()
//                 .fill(.clear)
//                 .frame(maxWidth: .infinity, maxHeight: .infinity)
//                 .background(.ultraThinMaterial)
//                 .environment(\.colorScheme, .dark)
//                 .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

//                 // Shadow / Bloom Layer Behind
//                 .background(
//                     RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                         .stroke(
//                             AngularGradient(
//                                 colors: aiColors, center: .center, startAngle: .degrees(phase),
//                                 endAngle: .degrees(phase + 360)),
//                             lineWidth: 30
//                         )
//                         .blur(radius: 20)
//                         .opacity(0.6)
//                         .blendMode(.screen)
//                 )

//                 // Crisp Inner Border Overlay
//                 .overlay(
//                     RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                         .stroke(
//                             AngularGradient(
//                                 colors: aiColors, center: .center, startAngle: .degrees(phase),
//                                 endAngle: .degrees(phase + 360)),
//                             lineWidth: 4
//                         )
//                         .blur(radius: 1.5)
//                         .blendMode(.screen)
//                 )
//         }
//         // We push the glow shape inward by the padding amount so it isn't clipped by the native NSWindow bounds
//         .padding(padding)
//         .onAppear {
//             withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
//                 phase = 360.0
//             }
//         }
//     }
// }

// // MARK: - Manager Logic
// @MainActor
// class WindowAsPanelManager {
//     static let shared = WindowAsPanelManager()

//     private func getOrCreatePanel(for id: String) -> WindowAsPanelAIHoverResponsivePanel {
//         if let container = WindowAsPanelPanelStorage.activePanels[id] {
//             return container.panel
//         }

//         let panel = WindowAsPanelAIHoverResponsivePanel(
//             contentRect: .zero,
//             styleMask: [.borderless, .nonactivatingPanel],
//             backing: .buffered,
//             defer: false
//         )

//         panel.isOpaque = false
//         panel.backgroundColor = .clear
//         panel.hasShadow = true
//         panel.ignoresMouseEvents = false
//         panel.isReleasedWhenClosed = false
//         panel.isMovableByWindowBackground = false

//         panel.hidesOnDeactivate = false
//         panel.level = .statusBar

//         panel.collectionBehavior = [
//             .canJoinAllSpaces,
//             .ignoresCycle,
//             .stationary,
//         ]

//         let newContainer = PanelInstanceContainer(panel: panel)
//         WindowAsPanelPanelStorage.activePanels[id] = newContainer
//         return panel
//     }

//     func show(
//         id: String, sendablePtr: WindowAsPanelSendableWindowPointer, x: Double, y: Double,
//         showAIGlow: Bool
//     ) {
//         if WindowAsPanelPanelStorage.activePanels[id] != nil {
//             clearPanelContents(for: id)
//         }

//         let panel = getOrCreatePanel(for: id)

//         let rawUnsafe = UnsafeMutableRawPointer(sendablePtr.rawPointer)
//         let sourceWindow = Unmanaged<NSWindow>.fromOpaque(rawUnsafe).takeUnretainedValue()

//         if let parent = sourceWindow.parent {
//             parent.removeChildWindow(sourceWindow)
//         }

//         guard let primaryScreen = sourceWindow.screen ?? NSScreen.main else { return }
//         let screenFrame = primaryScreen.frame
//         let targetSize = sourceWindow.frame.size

//         // Calculate layout with padding for glow bloom
//         let padding: CGFloat = showAIGlow ? 50.0 : 0.0
//         let panelWidth = targetSize.width + (padding * 2)
//         let panelHeight = targetSize.height + (padding * 2)
//         let customCornerRadius: CGFloat = 20.0

//         // Shift origin by padding to keep the webview exactly where the user clicked
//         let panelX = screenFrame.origin.x + CGFloat(x) - padding
//         let panelY =
//             screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height
//             - padding

//         let panelRect = NSRect(
//             origin: NSPoint(x: panelX, y: panelY),
//             size: NSSize(width: panelWidth, height: panelHeight))
//         panel.setFrame(panelRect, display: true, animate: false)

//         let handleHeight: CGFloat = 16.0
//         let viewToTrack: NSView

//         // MARK: - Core View Construction (Toggle based on flag)
//         if showAIGlow {
//             panel.hasShadow = false  // Let SwiftUI handle the natural glow bloom shadow natively

//             let hostView = NSHostingView(
//                 rootView: AIGlowBackgroundView(cornerRadius: customCornerRadius, padding: padding))
//             hostView.frame = NSRect(
//                 origin: .zero, size: NSSize(width: panelWidth, height: panelHeight))
//             hostView.autoresizingMask = [.width, .height]

//             let dragHandle = WindowAsPanelAISwiftDragHandleView()
//             // Inset the drag handle inward by the padding to rest atop the inner glass section
//             dragHandle.frame = NSRect(
//                 x: padding, y: targetSize.height - handleHeight + padding, width: targetSize.width,
//                 height: handleHeight)
//             dragHandle.autoresizingMask = [.width, .minYMargin]
//             hostView.addSubview(dragHandle)

//             panel.contentView = hostView
//             viewToTrack = hostView

//         } else {
//             panel.hasShadow = true

//             let containerView = NSView(frame: NSRect(origin: .zero, size: targetSize))
//             containerView.autoresizingMask = [.width, .height]

//             let visualEffectView = NSVisualEffectView()
//             visualEffectView.frame = containerView.bounds
//             visualEffectView.autoresizingMask = [.width, .height]

//             visualEffectView.wantsLayer = true
//             visualEffectView.layer?.masksToBounds = true
//             visualEffectView.layer?.cornerRadius = customCornerRadius
//             visualEffectView.material = .popover
//             visualEffectView.blendingMode = .withinWindow
//             visualEffectView.state = .active

//             let dragHandle = WindowAsPanelAISwiftDragHandleView()
//             dragHandle.frame = NSRect(
//                 x: 0, y: targetSize.height - handleHeight, width: targetSize.width,
//                 height: handleHeight)
//             dragHandle.autoresizingMask = [.width, .minYMargin]
//             visualEffectView.addSubview(dragHandle)

//             containerView.addSubview(visualEffectView)
//             panel.contentView = containerView
//             viewToTrack = containerView
//         }

//         // Configure the Tauri source window to rest inside the shell
//         sourceWindow.styleMask = [.borderless]
//         sourceWindow.isOpaque = false
//         sourceWindow.backgroundColor = .clear
//         sourceWindow.hasShadow = false

//         // Add padding offset so the webview layers perfectly inside the inner bounding box
//         sourceWindow.setFrame(
//             NSRect(
//                 x: panelX + padding, y: panelY + padding, width: targetSize.width,
//                 height: targetSize.height - handleHeight), display: true)

//         panel.addChildWindow(sourceWindow, ordered: .above)

//         WindowAsPanelPanelStorage.isCleaningUp = false

//         panel.orderFrontRegardless()
//         panel.makeKey()
//         panel.invalidateShadow()

//         // Setup hover tracking based on inner bounding box
//         let trackingFrame = NSRect(
//             x: padding, y: padding, width: targetSize.width, height: targetSize.height)
//         let trackingArea = NSTrackingArea(
//             rect: trackingFrame,
//             options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
//             owner: viewToTrack,
//             userInfo: nil
//         )
//         viewToTrack.addTrackingArea(trackingArea)

//         // Persist references for updates & cleanup
//         if let container = WindowAsPanelPanelStorage.activePanels[id] {
//             container.sourceWindow = sourceWindow
//             container.trackingArea = trackingArea
//             container.targetSize = targetSize
//             container.hasAIGlow = showAIGlow
//         }

//         WindowAsPanelPanelStorage.isCleaningUp = false

//         window_as_panel_event(.Opened(panel_id: RustString(id)))  // notify rust
//     }

//     func movePanel(id: String, x: Double, y: Double) {
//         guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
//         let panel = container.panel
//         let targetSize = container.targetSize
//         let padding: CGFloat = container.hasAIGlow ? 50.0 : 0.0

//         guard let primaryScreen = panel.screen ?? NSScreen.main else { return }
//         let screenFrame = primaryScreen.frame

//         // Calculate new positions factoring in potential transparent padding bounds
//         let panelX = screenFrame.origin.x + CGFloat(x) - padding
//         let panelY =
//             screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height
//             - padding

//         let panelWidth = targetSize.width + (padding * 2)
//         let panelHeight = targetSize.height + (padding * 2)
//         let panelRect = NSRect(
//             origin: NSPoint(x: panelX, y: panelY),
//             size: NSSize(width: panelWidth, height: panelHeight))

//         panel.setFrame(panelRect, display: true, animate: false)

//         if let sourceWindow = container.sourceWindow {
//             let handleHeight: CGFloat = 16.0
//             sourceWindow.setFrame(
//                 NSRect(
//                     x: panelX + padding, y: panelY + padding, width: targetSize.width,
//                     height: targetSize.height - handleHeight), display: true)
//         }
//     }

//     private func clearPanelContents(for id: String) {
//         guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
//         let panel = container.panel

//         if let sourceWindow = container.sourceWindow {
//             panel.removeChildWindow(sourceWindow)
//             sourceWindow.orderOut(nil)
//         }

//         if let content = panel.contentView {
//             if let tracking = container.trackingArea {
//                 content.removeTrackingArea(tracking)
//                 container.trackingArea = nil
//             }
//             for subview in content.subviews {
//                 subview.removeFromSuperview()
//             }
//         }
//         panel.contentView = nil
//     }

//     func closePanel(id: String) {
//         guard !WindowAsPanelPanelStorage.isCleaningUp,
//             let container = WindowAsPanelPanelStorage.activePanels[id],
//             container.panel.isVisible
//         else { return }

//         WindowAsPanelPanelStorage.isCleaningUp = true

//         let panel = container.panel
//         panel.orderOut(nil)

//         clearPanelContents(for: id)

//         WindowAsPanelPanelStorage.activePanels.removeValue(forKey: id)
//         WindowAsPanelPanelStorage.isCleaningUp = false

//         window_as_panel_event(.Closed(panel_id: RustString(id)))  // notify rust

//     }
// }

// // MARK: - Rust/Tauri Exposing APIs
// public func showWindowAsPanel(
//     id: RustString, windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double, showAIGlow: Bool
// ) {
//     let idStr = id.toString()
//     let ptrInt = Int(bitPattern: windowRawPtr)
//     let sendableContainer = WindowAsPanelSendableWindowPointer(address: ptrInt)

//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.show(
//             id: idStr, sendablePtr: sendableContainer, x: x, y: y, showAIGlow: showAIGlow)
//     }
// }

// public func moveWindowAsPanel(id: RustString, x: Double, y: Double) {
//     let idStr = id.toString()
//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.movePanel(id: idStr, x: x, y: y)
//     }
// }

// public func closeWindowAsPanel(id: RustString) {
//     let idStr = id.toString()

//     DispatchQueue.main.async {
//         WindowAsPanelManager.shared.closePanel(id: idStr)
//     }
// }

// public func isWindowAsPanelVisible(id: RustString) -> Bool {
//     let idStr = id.toString()

//     if Thread.isMainThread {
//         return MainActor.assumeIsolated {
//             WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
//         }
//     } else {
//         return DispatchQueue.main.sync {
//             return MainActor.assumeIsolated {
//                 WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
//             }
//         }
//     }
// }
//
import Cocoa
import SwiftUI  // Required for the Apple Intelligence glow effect

struct WindowAsPanelSendableWindowPointer: Sendable {
    let address: Int

    var rawPointer: OpaquePointer {
        OpaquePointer(bitPattern: address)!
    }
}

@MainActor
private final class PanelInstanceContainer {
    let panel: HoverResponsivePanel
    weak var sourceWindow: NSWindow?
    var trackingArea: NSTrackingArea?

    var targetSize: NSSize
    var hasAIGlow: Bool

    init(
        panel: HoverResponsivePanel, sourceWindow: NSWindow? = nil,
        trackingArea: NSTrackingArea? = nil, targetSize: NSSize = .zero, hasAIGlow: Bool = false
    ) {
        self.panel = panel
        self.sourceWindow = sourceWindow
        self.trackingArea = trackingArea
        self.targetSize = targetSize
        self.hasAIGlow = hasAIGlow
    }
}

@MainActor
private final class WindowAsPanelPanelStorage {
    static var activePanels: [String: PanelInstanceContainer] = [:]
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

class SwiftDragHandleView: NSView {
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
        if let window = self.window {
            if let parentPanel = window.parent as? NSPanel {
                parentPanel.performDrag(with: event)
            } else {
                window.performDrag(with: event)
            }
        } else {
            super.mouseDown(with: event)
        }
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }
}

// MARK: - SwiftUI Glow Component
struct AIGlowBackgroundView: View {
    @State private var phase: CGFloat = 0.0
    let aiColors = [Color.blue, Color.purple, Color.pink, Color.orange, Color.cyan, Color.blue]
    let cornerRadius: CGFloat
    let padding: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: aiColors, center: .center, startAngle: .degrees(phase),
                                endAngle: .degrees(phase + 360)),
                            lineWidth: 30
                        )
                        .blur(radius: 20)
                        .opacity(0.6)
                        .blendMode(.screen)
                )

                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: aiColors, center: .center, startAngle: .degrees(phase),
                                endAngle: .degrees(phase + 360)),
                            lineWidth: 4
                        )
                        .blur(radius: 1.5)
                        .blendMode(.screen)
                )
        }
        .padding(padding)
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                phase = 360.0
            }
        }
    }
}

// MARK: - Manager Logic
@MainActor
class WindowAsPanelManager {
    static let shared = WindowAsPanelManager()

    private func getOrCreatePanel(for id: String) -> HoverResponsivePanel {
        if let container = WindowAsPanelPanelStorage.activePanels[id] {
            return container.panel
        }

        let panel = HoverResponsivePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
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
        panel.level = .statusBar

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .ignoresCycle,
            .stationary,
        ]

        let newContainer = PanelInstanceContainer(panel: panel)
        WindowAsPanelPanelStorage.activePanels[id] = newContainer
        return panel
    }

    func show(
        id: String, sendablePtr: WindowAsPanelSendableWindowPointer, x: Double, y: Double,
        showAIGlow: Bool
    ) {
        if WindowAsPanelPanelStorage.activePanels[id] != nil {
            clearPanelContents(for: id)
        }

        let panel = getOrCreatePanel(for: id)

        let rawUnsafe = UnsafeMutableRawPointer(sendablePtr.rawPointer)
        let sourceWindow = Unmanaged<NSWindow>.fromOpaque(rawUnsafe).takeUnretainedValue()

        if let parent = sourceWindow.parent {
            parent.removeChildWindow(sourceWindow)
        }

        guard let primaryScreen = sourceWindow.screen ?? NSScreen.main else { return }
        let screenFrame = primaryScreen.frame
        let targetSize = sourceWindow.frame.size

        let padding: CGFloat = showAIGlow ? 50.0 : 0.0
        let panelWidth = targetSize.width + (padding * 2)
        let panelHeight = targetSize.height + (padding * 2)
        let customCornerRadius: CGFloat = 20.0

        let panelX = screenFrame.origin.x + CGFloat(x) - padding
        let panelY =
            screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height
            - padding

        let panelRect = NSRect(
            origin: NSPoint(x: panelX, y: panelY),
            size: NSSize(width: panelWidth, height: panelHeight))
        panel.setFrame(panelRect, display: true, animate: false)

        let handleHeight: CGFloat = 16.0
        let viewToTrack: NSView

        // MARK: - Core View Construction
        if showAIGlow {
            panel.hasShadow = false

            // 1. Create a neutral container view so NSHostingView doesn't swallow events
            let containerView = NSView(
                frame: NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight)))
            containerView.autoresizingMask = [.width, .height]

            // 2. Add the SwiftUI Background
            let hostView = NSHostingView(
                rootView: AIGlowBackgroundView(cornerRadius: customCornerRadius, padding: padding))
            hostView.frame = containerView.bounds
            hostView.autoresizingMask = [.width, .height]
            containerView.addSubview(hostView)

            // 3. Add the Drag Handle ON TOP as a sibling
            let dragHandle = SwiftDragHandleView()
            dragHandle.frame = NSRect(
                x: padding, y: targetSize.height - handleHeight + padding, width: targetSize.width,
                height: handleHeight)
            dragHandle.autoresizingMask = [.width, .minYMargin]
            containerView.addSubview(dragHandle)

            panel.contentView = containerView
            viewToTrack = containerView

        } else {
            panel.hasShadow = true

            let containerView = NSView(frame: NSRect(origin: .zero, size: targetSize))
            containerView.autoresizingMask = [.width, .height]

            let visualEffectView = NSVisualEffectView()
            visualEffectView.frame = containerView.bounds
            visualEffectView.autoresizingMask = [.width, .height]

            visualEffectView.wantsLayer = true
            visualEffectView.layer?.masksToBounds = true
            visualEffectView.layer?.cornerRadius = customCornerRadius
            visualEffectView.material = .popover
            visualEffectView.blendingMode = .withinWindow
            visualEffectView.state = .active

            let dragHandle = SwiftDragHandleView()
            dragHandle.frame = NSRect(
                x: 0, y: targetSize.height - handleHeight, width: targetSize.width,
                height: handleHeight)
            dragHandle.autoresizingMask = [.width, .minYMargin]
            visualEffectView.addSubview(dragHandle)

            containerView.addSubview(visualEffectView)
            panel.contentView = containerView
            viewToTrack = containerView
        }

        sourceWindow.styleMask = [.borderless]
        sourceWindow.isOpaque = false
        sourceWindow.backgroundColor = .clear
        sourceWindow.hasShadow = false

        sourceWindow.setFrame(
            NSRect(
                x: panelX + padding, y: panelY + padding, width: targetSize.width,
                height: targetSize.height - handleHeight), display: true)

        panel.addChildWindow(sourceWindow, ordered: .above)

        WindowAsPanelPanelStorage.isCleaningUp = false

        panel.orderFrontRegardless()
        panel.makeKey()
        panel.invalidateShadow()

        let trackingFrame = NSRect(
            x: padding, y: padding, width: targetSize.width, height: targetSize.height)
        let trackingArea = NSTrackingArea(
            rect: trackingFrame,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: viewToTrack,
            userInfo: nil
        )
        viewToTrack.addTrackingArea(trackingArea)

        if let container = WindowAsPanelPanelStorage.activePanels[id] {
            container.sourceWindow = sourceWindow
            container.trackingArea = trackingArea
            container.targetSize = targetSize
            container.hasAIGlow = showAIGlow
        }

        WindowAsPanelPanelStorage.isCleaningUp = false

        window_as_panel_event(.Opened(panel_id: RustString(id)))
    }

    func movePanel(id: String, x: Double, y: Double) {
        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        let panel = container.panel
        let targetSize = container.targetSize
        let padding: CGFloat = container.hasAIGlow ? 50.0 : 0.0

        guard let primaryScreen = panel.screen ?? NSScreen.main else { return }
        let screenFrame = primaryScreen.frame

        let panelX = screenFrame.origin.x + CGFloat(x) - padding
        let panelY =
            screenFrame.origin.y + (screenFrame.size.height - CGFloat(y)) - targetSize.height
            - padding

        let panelWidth = targetSize.width + (padding * 2)
        let panelHeight = targetSize.height + (padding * 2)
        let panelRect = NSRect(
            origin: NSPoint(x: panelX, y: panelY),
            size: NSSize(width: panelWidth, height: panelHeight))

        panel.setFrame(panelRect, display: true, animate: false)

        if let sourceWindow = container.sourceWindow {
            let handleHeight: CGFloat = 16.0
            sourceWindow.setFrame(
                NSRect(
                    x: panelX + padding, y: panelY + padding, width: targetSize.width,
                    height: targetSize.height - handleHeight), display: true)
        }
    }

    private func clearPanelContents(for id: String) {
        guard let container = WindowAsPanelPanelStorage.activePanels[id] else { return }
        let panel = container.panel

        if let sourceWindow = container.sourceWindow {
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

// MARK: - Rust/Tauri Exposing APIs
public func showWindowAsPanel(
    id: RustString, windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double, showAIGlow: Bool
) {
    let idStr = id.toString()
    let ptrInt = Int(bitPattern: windowRawPtr)
    let sendableContainer = WindowAsPanelSendableWindowPointer(address: ptrInt)

    DispatchQueue.main.async {
        WindowAsPanelManager.shared.show(
            id: idStr, sendablePtr: sendableContainer, x: x, y: y, showAIGlow: showAIGlow)
    }
}

public func moveWindowAsPanel(id: RustString, x: Double, y: Double) {
    let idStr = id.toString()
    DispatchQueue.main.async {
        WindowAsPanelManager.shared.movePanel(id: idStr, x: x, y: y)
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
