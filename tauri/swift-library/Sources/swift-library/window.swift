import Cocoa

@MainActor
public final class WindowResizeManager {

    public static func resizeWindow(
        windowAddress: Int,
        width: Double,
        height: Double
    ) {
        DispatchQueue.main.async {
            guard let rawPointer = UnsafeMutableRawPointer(bitPattern: windowAddress) else {
                return
            }

            let window = Unmanaged<NSWindow>.fromOpaque(rawPointer).takeUnretainedValue()

            let currentFrame = window.frame
            let targetSize = NSSize(width: CGFloat(width), height: CGFloat(height))

            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y + currentFrame.height - targetSize.height,
                width: targetSize.width,
                height: targetSize.height
            )

            NSAnimationContext.runAnimationGroup(
                { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                    window.animator().setFrame(newFrame, display: true)
                },
                completionHandler: {
                    Task { @MainActor in
                        if let targetRawPointer = UnsafeMutableRawPointer(bitPattern: windowAddress)
                        {
                            let strongWindow = Unmanaged<NSWindow>.fromOpaque(targetRawPointer)
                                .takeUnretainedValue()
                            strongWindow.contentView?.needsDisplay = true
                        }
                    }
                })
        }
    }
}

public func resizeWindow(
    nsWindowPtr: UnsafeMutableRawPointer,
    width: Double,
    height: Double
) {
    let windowAddress = Int(bitPattern: nsWindowPtr)

    MainActor.assumeIsolated {
        WindowResizeManager.resizeWindow(
            windowAddress: windowAddress,
            width: width,
            height: height
        )
    }
}
