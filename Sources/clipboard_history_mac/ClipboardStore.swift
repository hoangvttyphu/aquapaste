import AppKit
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private static let appSupportFolder = "AquaPaste"
    private static let legacyAppSupportFolder = "ClipVault"
    private static let persistenceFile = "clipboard-history.json"
    private static let imagesFolder = "images"

    /// Histories written by builds that inlined uncompressed images could reach
    /// hundreds of megabytes. Anything past this is set aside instead of being
    /// decoded into memory on launch.
    private static let maxHistoryFileBytes = 25 * 1024 * 1024

    private let pasteboard = NSPasteboard.general
    let maxItems: Int
    private var timer: Timer?
    private var lastObservedChangeCount: Int
    private let persistenceURL: URL
    private let imagesDirectory: URL

    init(maxItems: Int = 50) {
        let url = Self.makePersistenceURL()
        self.maxItems = maxItems
        self.persistenceURL = url
        self.imagesDirectory = url
            .deletingLastPathComponent()
            .appendingPathComponent(Self.imagesFolder, isDirectory: true)
        self.items = Self.loadPersistedItems(from: url, limit: maxItems)
        self.lastObservedChangeCount = pasteboard.changeCount

        ImageStorage.deleteOrphans(
            keeping: Set(items.compactMap(\.imageFile)),
            in: imagesDirectory
        )
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
        items.forEach(forget)
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
            // The full-resolution image is only pulled off disk at paste time.
            if let fileName = item.imageFile,
               let image = ImageStorage.readImage(named: fileName, in: imagesDirectory) {
                pasteboard.writeObjects([image])
            } else if let thumbnail = item.thumbnailImage {
                pasteboard.writeObjects([thumbnail])
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
           let item = ClipboardItem.fromImage(image, imagesDirectory: imagesDirectory) {
            insert(item)
        }
    }

    private func insert(_ newItem: ClipboardItem) {
        if items.first?.fingerprint == newItem.fingerprint {
            // Already at the top. Drop the image file we just wrote.
            forget(newItem)
            return
        }

        let duplicates = items.filter { $0.fingerprint == newItem.fingerprint }
        items.removeAll { $0.fingerprint == newItem.fingerprint }
        duplicates.forEach(forget)

        items.insert(newItem, at: 0)

        if items.count > maxItems {
            let overflow = items.count - maxItems
            let evicted = Array(items.suffix(overflow))
            items.removeLast(overflow)
            evicted.forEach(forget)
        }

        persist()
    }

    /// Releases everything an item owns: its cached thumbnail and its image file.
    private func forget(_ item: ClipboardItem) {
        ImageStorage.dropCachedThumbnail(id: item.id)

        if let fileName = item.imageFile {
            ImageStorage.deleteBlob(named: fileName, in: imagesDirectory)
        }
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
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.intValue ?? 0

        if fileSize > maxHistoryFileBytes {
            // Written by an older build that inlined uncompressed images. Move it
            // aside rather than pulling hundreds of megabytes into memory.
            let backup = url
                .deletingLastPathComponent()
                .appendingPathComponent("clipboard-history.oversized-backup.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let loadedItems = try JSONDecoder().decode([ClipboardItem].self, from: data)

            // Image entries written by older builds carried their bitmap inline and
            // decode with no file and no thumbnail. They can no longer be pasted,
            // so drop them instead of showing dead rows.
            let usableItems = loadedItems.filter { item in
                item.kind == .text || item.imageFile != nil || item.thumbnailData != nil
            }

            return Array(usableItems.prefix(limit))
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
