import AppKit
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private static let appSupportFolder = "AquaPaste"
    private static let legacyAppSupportFolder = "ClipVault"
    private static let persistenceFile = "clipboard-history.json"

    private let pasteboard = NSPasteboard.general
    let maxItems: Int
    private var timer: Timer?
    private var lastObservedChangeCount: Int
    private let persistenceURL: URL

    init(maxItems: Int = 50) {
        self.maxItems = maxItems
        self.persistenceURL = Self.makePersistenceURL()
        self.items = Self.loadPersistedItems(from: persistenceURL, limit: maxItems)
        self.lastObservedChangeCount = pasteboard.changeCount
    }

    func startMonitoring() {
        captureClipboardIfNeeded(force: true)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureClipboardIfNeeded()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func clear() {
        items.removeAll()
        persist()
    }

    func activate(_ item: ClipboardItem) {
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            if let textContent = item.textContent {
                pasteboard.setString(textContent, forType: .string)
            }
        case .image:
            if let image = item.imagePreview {
                pasteboard.writeObjects([image])
            }
        }

        lastObservedChangeCount = pasteboard.changeCount
    }

    private func captureClipboardIfNeeded(force: Bool = false) {
        guard force || pasteboard.changeCount != lastObservedChangeCount else {
            return
        }

        lastObservedChangeCount = pasteboard.changeCount

        if let text = pasteboard.string(forType: .string),
           let item = ClipboardItem.fromText(text) {
            insert(item)
            return
        }

        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let item = ClipboardItem.fromImage(image) {
            insert(item)
        }
    }

    private func insert(_ newItem: ClipboardItem) {
        if items.first?.fingerprint == newItem.fingerprint {
            return
        }

        items.removeAll { $0.fingerprint == newItem.fingerprint }
        items.insert(newItem, at: 0)

        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }

        persist()
    }

    private func persist() {
        do {
            let directory = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try JSONEncoder().encode(items)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to persist clipboard history: \(error)")
        }
    }

    private static func loadPersistedItems(from url: URL, limit: Int) -> [ClipboardItem] {
        do {
            let data = try Data(contentsOf: url)
            let loadedItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
            return Array(loadedItems.prefix(limit))
        } catch {
            return []
        }
    }

    private static func makePersistenceURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let newURL = baseURL
            .appendingPathComponent(appSupportFolder, isDirectory: true)
            .appendingPathComponent(persistenceFile, isDirectory: false)

        let legacyURL = baseURL
            .appendingPathComponent(legacyAppSupportFolder, isDirectory: true)
            .appendingPathComponent(persistenceFile, isDirectory: false)

        if FileManager.default.fileExists(atPath: newURL.path) == false,
           FileManager.default.fileExists(atPath: legacyURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: newURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                try FileManager.default.copyItem(at: legacyURL, to: newURL)
            } catch {
                print("Failed to migrate legacy clipboard history: \(error)")
            }
        }

        return newURL
    }
}
