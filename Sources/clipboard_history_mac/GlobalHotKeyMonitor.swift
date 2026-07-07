import Carbon.HIToolbox
import Foundation

final class GlobalHotKeyMonitor {
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func start() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData, let event else {
                    return noErr
                }

                let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if hotKeyID.id == 1 {
                    monitor.action()
                }

                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: 0x43565054, id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            print("Could not register Option+V hotkey. Status: \(status)")
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}
