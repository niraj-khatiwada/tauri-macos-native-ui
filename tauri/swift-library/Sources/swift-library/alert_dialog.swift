import Cocoa

public struct AlertActionButton: Decodable {
    let id: String
    let label: String
    let type: String

    public init(id: String, label: String, type: String) {
        self.id = id
        self.label = label
        self.type = type
    }
}

public enum AlertDialogEvent {
    case Opened(alertId: String)
    case ActionClicked(alertId: String, buttonId: String)
    case Closed(alertId: String)
}

@MainActor
private final class AlertDialogInstanceContainer {
    let alert: NSAlert
    let id: String

    init(id: String, alert: NSAlert) {
        self.id = id
        self.alert = alert
    }
}

@MainActor
private final class AlertDialogStorage {
    static var activeAlerts: [String: AlertDialogInstanceContainer] = [:]
}

@MainActor
public class AlertDialogManager {
    public static let shared = AlertDialogManager()

    public func openAlertDialog(
        id: String,
        title: String,
        description: String,
        actionButtons: [AlertActionButton],
        detached: Bool
    ) {
        if AlertDialogStorage.activeAlerts[id] != nil {
            closeAlertDialog(id: id)
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = description

        let primaryType = actionButtons.first?.type ?? "default"
        if primaryType == "warning" {
            alert.alertStyle = .critical
        } else {
            alert.alertStyle = .informational
        }

        for (index, buttonData) in actionButtons.enumerated() {
            let button = alert.addButton(withTitle: buttonData.label)
            let identifier = NSUserInterfaceItemIdentifier(buttonData.id)
            button.identifier = identifier

            if buttonData.type == "default" || buttonData.type == "info" {
                if index == 0 {
                    button.keyEquivalent = "\r"
                }
            } else if buttonData.type == "warning" {
                if #available(macOS 14.0, *) {
                    button.hasDestructiveAction = true
                }
            }

            switch buttonData.type {
            case "info":
                button.isHighlighted = true
                if #available(macOS 10.14, *) {
                    button.bezelColor = NSColor.controlAccentColor
                } else {
                    button.bezelColor = NSColor.systemBlue
                }

            case "warning":
                button.isHighlighted = true
                if #available(macOS 14.0, *) {
                    button.hasDestructiveAction = true
                } else {
                    button.bezelColor = NSColor.systemRed
                }

            case "default":
                fallthrough
            default:
                button.isHighlighted = false
                button.bezelColor = nil

                if index == 0 && buttonData.type == "default" {
                    button.keyEquivalent = ""
                }
            }
        }

        let container = AlertDialogInstanceContainer(id: id, alert: alert)
        AlertDialogStorage.activeAlerts[id] = container

        triggerAlertEvent(.Opened(alertId: id))

        if detached {
            let response = alert.runModal()
            let clickedButtonIndex = response.rawValue - 1000
            if clickedButtonIndex >= 0 && clickedButtonIndex < actionButtons.count {
                let targetButton = actionButtons[clickedButtonIndex]
                self.triggerAlertEvent(.ActionClicked(alertId: id, buttonId: targetButton.id))
            }
            self.cleanupAlertState(id: id)
        } else {
            alert.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { response in
                let clickedButtonIndex = response.rawValue - 1000
                if clickedButtonIndex >= 0 && clickedButtonIndex < actionButtons.count {
                    let targetButton = actionButtons[clickedButtonIndex]
                    self.triggerAlertEvent(.ActionClicked(alertId: id, buttonId: targetButton.id))
                }
                self.cleanupAlertState(id: id)
            }
        }
    }

    public func closeAlertDialog(id: String) {
        guard let container = AlertDialogStorage.activeAlerts[id] else { return }

        if let window = container.alert.window.sheetParent {
            window.endSheet(container.alert.window)
        } else {
            NSApp.stopModal(withCode: .cancel)
            container.alert.window.orderOut(nil)
        }

        cleanupAlertState(id: id)
    }

    private func cleanupAlertState(id: String) {
        if AlertDialogStorage.activeAlerts[id] != nil {
            AlertDialogStorage.activeAlerts.removeValue(forKey: id)
            triggerAlertEvent(.Closed(alertId: id))
        }
    }

    private func triggerAlertEvent(_ event: AlertDialogEvent) {
        switch event {
        case .Opened(let alertId):
            on_alert_dialog_event(alertId, .Opened)
        case .ActionClicked(let alertId, let buttonId):
            on_alert_dialog_event(alertId, .ActionClicked(button_id: buttonId.intoRustString()))
        case .Closed(let alertId):
            on_alert_dialog_event(alertId, .Closed)
        }
    }
}

public func showNativeAlertDialog(
    id: RustString,
    title: RustString,
    description: RustString,
    buttonsJson: RustString,
    detached: Bool
) {
    let idStr = id.toString()
    let titleStr = title.toString()
    let descStr = description.toString()
    let jsonStr = buttonsJson.toString()

    let jsonData = Data(jsonStr.utf8)
    var parsedButtons: [AlertActionButton] = []

    do {
        parsedButtons = try JSONDecoder().decode([AlertActionButton].self, from: jsonData)
    } catch {
        print("Failed to decode alert buttons JSON: \(error)")
        parsedButtons = [AlertActionButton(id: "ok", label: "OK", type: "default")]
    }

    DispatchQueue.main.async {
        AlertDialogManager.shared.openAlertDialog(
            id: idStr,
            title: titleStr,
            description: descStr,
            actionButtons: parsedButtons,
            detached: detached
        )
    }
}

public func closeNativeAlertDialog(id: RustString) {
    let idStr = id.toString()
    DispatchQueue.main.async {
        AlertDialogManager.shared.closeAlertDialog(id: idStr)
    }
}
