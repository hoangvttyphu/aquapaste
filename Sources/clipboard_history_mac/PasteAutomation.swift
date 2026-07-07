import ApplicationServices
import Carbon.HIToolbox
import Foundation

enum PasteAutomation {
    static var canAutoPaste: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func pasteFromClipboardIfPossible() -> Bool {
        guard canAutoPaste else {
            let options = [
                "AXTrustedCheckOptionPrompt": true,
            ] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            return false
        }

        guard let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: true
        ),
        let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: false
        ) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
