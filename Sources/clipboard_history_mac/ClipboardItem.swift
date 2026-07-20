import AppKit
import CryptoKit
import Foundation

enum ClipboardItemKind: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: ClipboardItemKind
    let createdAt: Date
    let title: String
    let subtitle: String
    let textContent: String?
    /// File name of the full-resolution PNG stored on disk. Nil for text items.
    let imageFile: String?
    /// Small PNG preview kept in the history file so drawing the panel stays cheap.
    let thumbnailData: Data?
    let fingerprint: String

    /// Preview shown in the list. Decoded once and cached, never the full-size image.
    @MainActor
    var thumbnailImage: NSImage? {
        guard let thumbnailData else {
            return nil
        }

        return ImageStorage.cachedThumbnail(id: id, data: thumbnailData)
    }

    var searchableText: String {
        [title, subtitle, textContent ?? ""]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func fromText(_ value: String) -> ClipboardItem? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return nil
        }

        let normalized = trimmed.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        let title = String(normalized.prefix(80))
        let subtitle = L("\(trimmed.count) characters", "\(trimmed.count) ký tự")

        return ClipboardItem(
            id: UUID(),
            kind: .text,
            createdAt: Date(),
            title: title,
            subtitle: subtitle,
            textContent: trimmed,
            imageFile: nil,
            thumbnailData: nil,
            fingerprint: "text:\(normalized)"
        )
    }

    /// Compresses the image to PNG, writes it next to the history file, and keeps
    /// only a small thumbnail in memory.
    @MainActor
    static func fromImage(_ image: NSImage, imagesDirectory: URL) -> ClipboardItem? {
        guard let pngData = ImageStorage.pngData(from: image) else {
            return nil
        }

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let digest = SHA256.hash(data: pngData)
            .map { String(format: "%02x", $0) }
            .joined()

        let id = UUID()
        let fileName = "\(id.uuidString).png"

        do {
            try ImageStorage.writeBlob(pngData, named: fileName, in: imagesDirectory)
        } catch {
            print("Failed to store clipboard image: \(error)")
            return nil
        }

        return ClipboardItem(
            id: id,
            kind: .image,
            createdAt: Date(),
            title: L("Image", "Hình ảnh"),
            subtitle: "\(width) x \(height)",
            textContent: nil,
            imageFile: fileName,
            thumbnailData: ImageStorage.thumbnailPNGData(from: image),
            fingerprint: "image:\(digest)"
        )
    }
}
