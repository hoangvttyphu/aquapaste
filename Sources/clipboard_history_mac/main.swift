import AppKit

let application = NSApplication.shared
let appDelegate = ClipboardHistoryAppDelegate()

application.setActivationPolicy(.accessory)
application.delegate = appDelegate
application.run()
