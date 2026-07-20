import AppKit
import Foundation

/// Keeps full-resolution clipboard images as compressed PNG files on disk, so the
/// in-memory history only ever holds small thumbnails.
///
/// Earlier builds stored `tiffRepresentation` (uncompressed) inline in the history
/// JSON, which pushed a 50 item history past 250 MB and kept every full-size bitmap
/// resident in RAM.
enum ImageStorage {
    /// Longest edge of the preview thumbnail kept inside the history file.
    static let thumbnailMaxDimension: CGFloat = 140

    @MainActor
    private static let thumbnailCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 120
        return cache
    }()

    // MARK: - Encoding

    @MainActor
    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff) else {
            return nil
        }

        return representation.representation(using: .png, properties: [:])
    }

    @MainActor
    static func thumbnailPNGData(from image: NSImage) -> Data? {
        let source = image.size
        guard source.width > 0, source.height > 0 else {
            return nil
        }

        let scale = min(1, thumbnailMaxDimension / max(source.width, source.height))
        let pixelsWide = max(1, Int((source.width * scale).rounded()))
        let pixelsHigh = max(1, Int((source.height * scale).rounded()))

        // Draw straight into a bitmap of the exact pixel size. Using lockFocus here
        // would render at the screen's backing scale (2x on Retina) and quadruple
        // the thumbnail size for no visible gain.
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        representation.size = NSSize(width: pixelsWide, height: pixelsHigh)

        guard let context = NSGraphicsContext(bitmapImageRep: representation) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(
            in: NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh),
            from: NSRect(origin: .zero, size: source),
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        return representation.representation(using: .png, properties: [:])
    }

    // MARK: - Thumbnail cache

    /// Decodes a thumbnail once and reuses it, so SwiftUI redraws stay cheap.
    @MainActor
    static func cachedThumbnail(id: UUID, data: Data) -> NSImage? {
        let key = id.uuidString as NSString

        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        guard let image = NSImage(data: data) else {
            return nil
        }

        thumbnailCache.setObject(image, forKey: key)
        return image
    }

    @MainActor
    static func dropCachedThumbnail(id: UUID) {
        thumbnailCache.removeObject(forKey: id.uuidString as NSString)
    }

    // MARK: - Image files on disk

    static func writeBlob(_ data: Data, named fileName: String, in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent(fileName), options: .atomic)
    }

    static func readImage(named fileName: String, in directory: URL) -> NSImage? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(fileName)) else {
            return nil
        }

        return NSImage(data: data)
    }

    static func deleteBlob(named fileName: String, in directory: URL) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(fileName))
    }

    /// Removes image files that no longer belong to any item in the history.
    static func deleteOrphans(keeping used: Set<String>, in directory: URL) {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return
        }

        for name in names where used.contains(name) == false {
            deleteBlob(named: name, in: directory)
        }
    }
}
