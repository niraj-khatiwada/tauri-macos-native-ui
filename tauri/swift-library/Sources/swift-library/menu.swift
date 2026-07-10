import Cocoa

struct MenuItemData: Codable {
    let id: String
    let title: String
    let disabled: Bool?
    let items: [MenuItemData]?
}

@MainActor
class NativeMenuManager: NSObject, NSMenuDelegate {
    static let shared = NativeMenuManager()

    private var currentMenu: NSMenu?
    
    func openMenu(x: Double, y: Double, itemsJson: String, focusParentWindow: Bool) {
        var targetWindow: NSWindow? = NSApplication.shared.keyWindow
        
        if targetWindow == nil {
            let mouseLocation = NSEvent.mouseLocation
            let windows = NSApplication.shared.windows
            targetWindow = windows.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) && $0.isVisible })
                ?? windows.first(where: { $0.isVisible })
        }
        
        guard let window = targetWindow, let parentContentView = window.contentView else {
            print("Could not find a valid application window")
            return
        }
        
        guard let data = itemsJson.data(using: .utf8),
              let menuItems = try? JSONDecoder().decode([MenuItemData].self, from: data) else {
            print("Failed to parse menu items JSON")
            return
        }
        
        closeMenu()
        
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        
        for itemData in menuItems {
            let menuItem = buildMenuItem(from: itemData)
            menu.addItem(menuItem)
        }
        
        self.currentMenu = menu
        
        let windowHeight = parentContentView.bounds.height
        let adjustedY = windowHeight - CGFloat(y)
        let adjustedX = CGFloat(x)
        let targetPoint = NSPoint(x: adjustedX, y: adjustedY)
        
        WindowAsPopoverManager.shared.isHigherLayerActive = true
        
        if focusParentWindow {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        menu.popUp(positioning: nil, at: targetPoint, in: parentContentView)
        
        WindowAsPopoverManager.shared.isHigherLayerActive = false
    }

    func closeMenu() {
        if let menu = currentMenu {
            menu.cancelTracking()
            self.currentMenu = nil
        }
    }

    private func buildMenuItem(from data: MenuItemData) -> NSMenuItem {
        let hasSubitems = data.items != nil && !data.items!.isEmpty

        let menuItem = NSMenuItem(
            title: data.title,
            action: hasSubitems ? nil : #selector(menuItemAction(_:)),
            keyEquivalent: ""
        )
        
        if !hasSubitems {
            menuItem.target = self
        }
        
        menuItem.representedObject = data.id
        menuItem.isEnabled = !(data.disabled ?? false)

        if let subitems = data.items, !subitems.isEmpty {
            let submenu = NSMenu()
            submenu.autoenablesItems = false
            for subData in subitems {
                submenu.addItem(buildMenuItem(from: subData))
            }
            menuItem.submenu = submenu
        }

        return menuItem
    }

    @objc private func menuItemAction(_ sender: NSMenuItem) {
        if let itemId = sender.representedObject as? String {
            on_menu_item_clicked_event(itemId)
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu == self.currentMenu {
            self.currentMenu = nil
        }
    }
}

public func openNativeMenu(x: Double, y: Double, itemsJson: RustString, focusParentWindow: Bool) {
    DispatchQueue.main.async {
        NativeMenuManager.shared.openMenu(
            x: x,
            y: y,
            itemsJson: itemsJson.toString(),
            focusParentWindow: focusParentWindow
        )
    }
}

public func closeNativeMenu() {
    DispatchQueue.main.async {
        NativeMenuManager.shared.closeMenu()
    }
}
