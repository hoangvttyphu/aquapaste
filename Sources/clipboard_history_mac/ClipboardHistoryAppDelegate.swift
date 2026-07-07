import AppKit

@MainActor
final class ClipboardHistoryAppDelegate: NSObject, NSApplicationDelegate {
    private let store = ClipboardStore(maxItems: 50)
    private var panelController: ClipboardPanelController?
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var statusItem: NSStatusItem?
    private var previouslyActiveApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenuBar()
        configurePanel()
        configureHotKey()
        store.startMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configurePanel() {
        panelController = ClipboardPanelController(
            store: store,
            onSelect: { [weak self] item in
                self?.handleSelection(item)
            },
            onClose: { [weak self] in
                self?.panelController?.hide()
            }
        )
    }

    private func configureHotKey() {
        hotKeyMonitor = GlobalHotKeyMonitor { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
        hotKeyMonitor?.start()
    }

    private func configureMenuBar() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "AquaPaste")
            button.toolTip = "AquaPaste"
        }

        let menu = NSMenu()
        let showItem = NSMenuItem(title: "Mở AquaPaste", action: #selector(showPanelFromMenu), keyEquivalent: "v")
        showItem.keyEquivalentModifierMask = [.option]
        showItem.target = self
        menu.addItem(showItem)

        let clearItem = NSMenuItem(title: "Xóa lịch sử", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Thoát", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    private func togglePanel() {
        guard let panelController else {
            return
        }

        if panelController.isVisible {
            panelController.hide()
            return
        }

        rememberFrontmostApp()
        panelController.show()
    }

    private func rememberFrontmostApp() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != currentPID {
            previouslyActiveApp = frontmost
        }
    }

    private func handleSelection(_ item: ClipboardItem) {
        store.activate(item)
        panelController?.hide()

        if let previouslyActiveApp {
            previouslyActiveApp.activate(options: [])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            _ = PasteAutomation.pasteFromClipboardIfPossible()
        }
    }

    @objc
    private func showPanelFromMenu() {
        togglePanel()
    }

    @objc
    private func clearHistory() {
        store.clear()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}
