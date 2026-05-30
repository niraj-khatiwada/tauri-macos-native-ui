import Cocoa
import SwiftRs
import WebKit

class WebViewController: NSViewController {
    var targetURL: URL?
    var hashFragment: String?
    var enableDevTools: Bool?

    init(url: URL?, fragment: String?, enableDevTools: Bool?) {
        self.targetURL = url
        self.hashFragment = fragment
        self.enableDevTools = enableDevTools
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // 1. Establish the base view size
        let viewBounds = NSRect(x: 0, y: 0, width: 400, height: 500)
        self.view = NSView(frame: viewBounds)

        // 2. Create the macOS Native Vibrancy Layer (Frosted Glass)
        let visualEffectView = NSVisualEffectView(frame: viewBounds)
        visualEffectView.autoresizingMask = [.width, .height]

        // .popover matches the exact system blur styling of Spotlight and Raycast
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active

        // Add the blur view as the foundation layer
        self.view.addSubview(visualEffectView)

        // 3. Set up the WKWebView Configuration
        let config = WKWebViewConfiguration()

        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        if enableDevTools==true {
            config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        }

        let webView = WKWebView(frame: viewBounds, configuration: config)
        webView.autoresizingMask = [.width, .height]

        // Disable the default opaque background color channels
        webView.setValue(false, forKey: "drawsBackground") // Disables the default solid canvas drawing
        webView.wantsLayer = true                          // Tells macOS to back this view with a core animation layer
        webView.layer?.backgroundColor = .clear            // Forces the layer channel to be 100% transparent

        // 4. Load the React build assets
        if let url = targetURL {
            if url.isFileURL {
                // Extract the parent directory enclosing your asset chunks (/dist)
                let baseDirectory = url.deletingLastPathComponent()

                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.fragment = hashFragment
                if let finalRoutedURL = urlComponents?.url {
                    // Load the full compound URL while granting access to the root asset directory
                    webView.loadFileURL(finalRoutedURL, allowingReadAccessTo: baseDirectory)
                    print("🚀 WKWebView successfully routing to local bundle: \(finalRoutedURL.absoluteString)")
                }
            } else {
                // Reconstruct the http://localhost URL with the routing fragment attached!
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.fragment = hashFragment

                if let finalDevURL = urlComponents?.url {
                    let request = URLRequest(url: finalDevURL)
                    webView.load(request)
                    print("🌐 WKWebView routing to local dev server: \(finalDevURL.absoluteString)")
                }
            }
        }

        // Stack the transparent webview directly on top of the blur view
        self.view.addSubview(webView)
    }

}

@_cdecl("show_webview_popover")
public func showWebviewPopover(windowPtr: UnsafeRawPointer, url: SRString, x: Double, y: Double, enableDevTools: Bool) {
    let urlString = url.toString()

    let parts = urlString.components(separatedBy: "#")
    let url = parts[0]
    let hashFragment = parts.count > 1 ? parts[1] : nil

    guard let targetURL = URL(string: url) else { return }

    let windowAddress = Int(bitPattern: windowPtr)

    DispatchQueue.main.async {
        guard let safePtr = UnsafeRawPointer(bitPattern: windowAddress) else { return }
        let parentWindow = Unmanaged<NSWindow>.fromOpaque(safePtr).takeUnretainedValue()
        guard let parentContentView = parentWindow.contentView else { return }

        let windowHeight = parentContentView.bounds.height
        let adjustedY = windowHeight - CGFloat(y)
        let targetRect = NSRect(x: CGFloat(x), y: adjustedY, width: 1, height: 1)

        let popover = NSPopover()
        popover.contentViewController = WebViewController(url: targetURL, fragment: hashFragment, enableDevTools: enableDevTools)
        popover.behavior = .transient
        popover.animates = true

        popover.show(
            relativeTo: targetRect,
            of: parentContentView,
            preferredEdge: .minY
        )
    }
}
