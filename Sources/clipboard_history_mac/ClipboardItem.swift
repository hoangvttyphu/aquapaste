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
    let imageData: Data?
    let fingerprint: String

    var imagePreview: NSImage? {
        guard let imageData else {
            return nil
        }

        return NSImage(data: imageData)
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
            imageData: nil,
            fingerprint: "text:\(normalized)"
        )
    }

    static func fromImage(_ image: NSImage) -> ClipboardItem? {
        guard let imageData = image.tiffRepresentation else {
            return nil
        }

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        let digest = SHA256.hash(data: imageData)
            .map { String(format: "%02x", $0) }
            .joined()

        return ClipboardItem(
            id: UUID(),
            kind: .image,
            createdAt: Date(),
            title: L("Image", "Hình ảnh"),
            subtitle: "\(width) x \(height)",
            textContent: nil,
            imageData: imageData,
            fingerprint: "image:\(digest)"
        )
    }
}
