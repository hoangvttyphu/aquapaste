import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class ClipboardPanelController: NSObject, NSWindowDelegate {
    private let viewModel: ClipboardPanelViewModel
    private let window: NSWindow
    private var keyMonitor: LocalKeyMonitor?
    private let onSelect: (ClipboardItem) -> Void
    private let onClose: () -> Void

    init(
        store: ClipboardStore,
        onSelect: @escaping (ClipboardItem) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = ClipboardPanelViewModel(store: store)
        self.onSelect = onSelect
        self.onClose = onClose
        self.window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "AquaPaste"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .transient]
        window.delegate = self
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let rootView = ClipboardPanelView(
            viewModel: viewModel,
            onSelect: onSelect,
            onClose: onClose
        )
        window.contentViewController = NSHostingController(rootView: rootView)

        configureKeyMonitor()
    }

    var isVisible: Bool {
        window.isVisible
    }

    func show() {
        viewModel.refreshForPresentation()
        keyMonitor?.start()
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        keyMonitor?.stop()
        window.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func configureKeyMonitor() {
        keyMonitor = LocalKeyMonitor { [weak self] event in
            guard let self, self.window.isVisible else {
                return event
            }

            switch Int(event.keyCode) {
            case kVK_UpArrow:
                self.viewModel.moveSelection(offset: -1)
                return nil
            case kVK_DownArrow:
                self.viewModel.moveSelection(offset: 1)
                return nil
            case kVK_Return, kVK_ANSI_KeypadEnter:
                if let item = self.viewModel.selectedItem() {
                    self.onSelect(item)
                    return nil
                }
                return event
            case kVK_Escape:
                self.onClose()
                return nil
            default:
                return event
            }
        }
    }
}
