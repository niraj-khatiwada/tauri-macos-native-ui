// // import AppKit
// // import SwiftUI

// // // This attribute exposes the function directly to the C/Rust linker
// // @_cdecl("show_swift_panel")
// // public func show_swift_panel() {
// //     DispatchQueue.main.async {
// //         if let existingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "ai-panel" }
// //         ) {
// //             existingWindow.makeKeyAndOrderFront(nil)
// //             NSApp.activate(ignoringOtherApps: true)
// //             return
// //         }

// //         // FIX 1: Make the native window larger (420x320) to give the 320x220 panel room for its outer glow
// //         let panel = NSPanel(
// //             contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
// //             styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
// //             backing: .buffered,
// //             defer: false
// //         )

// //         panel.identifier = NSUserInterfaceItemIdentifier("ai-panel")

// //         panel.isFloatingPanel = true
// //         panel.hidesOnDeactivate = true
// //         panel.isMovableByWindowBackground = true
// //         panel.isOpaque = false
// //         panel.backgroundColor = .clear  // Native window is completely invisible
// //         panel.level = .statusBar
// //         panel.hasShadow = false  // Let SwiftUI handle the shadow/glow entirely
// //         panel.collectionBehavior = [
// //             .canJoinAllSpaces,
// //             .ignoresCycle,
// //             .stationary,
// //         ]

// //         // FIX 2: Remove the native layer cornerRadius and masksToBounds.
// //         // Let SwiftUI handle all the shaping natively.
// //         let contentView = NSHostingView(
// //             rootView: AIPanelView(onClose: { [weak panel] in
// //                 panel?.close()
// //             }))

// //         panel.contentView = contentView
// //         panel.center()
// //         panel.makeKeyAndOrderFront(nil)
// //         NSApp.activate(ignoringOtherApps: true)
// //     }
// // }

// // struct AIPanelView: View {
// //     @State private var phase: CGFloat = 0.0
// //     let aiColors = [Color.blue, Color.purple, Color.pink, Color.orange, Color.cyan, Color.blue]

// //     var onClose: () -> Void

// //     var body: some View {
// //         ZStack(alignment: .topTrailing) {

// //             // Core UI Content Layout
// //             VStack(spacing: 12) {
// //                 Spacer()
// //                 Image(systemName: "waveform")
// //                     .font(.system(size: 38, weight: .semibold))
// //                     .foregroundStyle(
// //                         LinearGradient(
// //                             colors: [.blue, .purple, .pink], startPoint: .topLeading,
// //                             endPoint: .bottomTrailing))
// //                 Text("Apple Intelligence")
// //                     .font(.headline)
// //                     .foregroundColor(.white)
// //                 Spacer()
// //             }
// //             .frame(maxWidth: .infinity, maxHeight: .infinity)

// //             // Top Right Close Button
// //             Button(action: {
// //                 onClose()
// //             }) {
// //                 Image(systemName: "xmark.circle.fill")
// //                     .font(.system(size: 20))
// //                     .foregroundColor(Color.white.opacity(0.4))
// //             }
// //             .buttonStyle(.plain)
// //             .padding(.top, 16)
// //             .padding(.trailing, 16)
// //         }
// //         .frame(width: 320, height: 220)  // The actual size of the glass panel
// //         .background(.ultraThinMaterial)
// //         .environment(\.colorScheme, .dark)
// //         // FIX 3: Use clipShape instead of cornerRadius to cleanly cut the glass
// //         .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

// //         // Background heavy atmospheric "shadow glow"
// //         .background(
// //             RoundedRectangle(cornerRadius: 28, style: .continuous)
// //                 .stroke(
// //                     AngularGradient(
// //                         colors: aiColors, center: .center, startAngle: .degrees(phase),
// //                         endAngle: .degrees(phase + 360)),
// //                     lineWidth: 30
// //                 )
// //                 .blur(radius: 10)
// //                 .opacity(0.6)
// //                 .blendMode(.screen)
// //         )
// //         // Crisp primary border overlay
// //         .overlay(
// //             RoundedRectangle(cornerRadius: 28, style: .continuous)
// //                 .stroke(
// //                     AngularGradient(
// //                         colors: aiColors, center: .center, startAngle: .degrees(phase),
// //                         endAngle: .degrees(phase + 360)),
// //                     lineWidth: 4
// //                 )
// //                 .blur(radius: 1.5)
// //                 .blendMode(.screen)
// //         )
// //         // FIX 4: Add padding so the outer glow doesn't hit the physical NSWindow edges
// //         .padding(50)
// //         .onAppear {
// //             withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
// //                 phase = 360.0
// //             }
// //         }
// //     }
// // }

// import Cocoa
// import SwiftUI  // Required for the Apple Intelligence glow effect

// struct WindowAsPanelAISendableWindowPointer: Sendable {
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
// class WindowAsPanelAIManager {
//     static let shared = WindowAsPanelAIManager()

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
// public func showWindowAsPanelAI(
//     id: RustString, windowRawPtr: UnsafeMutableRawPointer?, x: Double, y: Double, show_ai_glow: Bool
// ) {
//     let idStr = id.toString()
//     let ptrInt = Int(bitPattern: windowRawPtr)
//     let sendableContainer = WindowAsPanelSendableWindowPointer(address: ptrInt)

//     DispatchQueue.main.async {
//         WindowAsPanelAIManager.shared.show(
//             id: idStr, sendablePtr: sendableContainer, x: x, y: y, showAIGlow: show_ai_glow)
//     }
// }

// // public func moveWindowAsPanel(id: RustString, x: Double, y: Double) {
// //     let idStr = id.toString()
// //     DispatchQueue.main.async {
// //         WindowAsPanelAIManager.shared.movePanel(id: idStr, x: x, y: y)
// //     }
// // }

// // public func closeWindowAsPanel(id: RustString) {
// //     let idStr = id.toString()

// //     DispatchQueue.main.async {
// //         WindowAsPanelAIManager.shared.closePanel(id: idStr)
// //     }
// // }

// // public func isWindowAsPanelVisible(id: RustString) -> Bool {
// //     let idStr = id.toString()

// //     if Thread.isMainThread {
// //         return MainActor.assumeIsolated {
// //             WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
// //         }
// //     } else {
// //         return DispatchQueue.main.sync {
// //             return MainActor.assumeIsolated {
// //                 WindowAsPanelPanelStorage.activePanels[idStr]?.panel.isVisible ?? false
// //             }
// //         }
// //     }
// // }
