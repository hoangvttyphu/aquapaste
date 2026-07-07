import AppKit

final class LocalKeyMonitor {
    private var monitor: Any?
    private let onKeyDown: (NSEvent) -> NSEvent?

    init(onKeyDown: @escaping (NSEvent) -> NSEvent?) {
        self.onKeyDown = onKeyDown
    }

    func start() {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }

            return self.onKeyDown(event)
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }
}
