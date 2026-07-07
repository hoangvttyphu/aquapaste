import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var viewModel: ClipboardPanelViewModel
    let onSelect: (ClipboardItem) -> Void
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(alignment: .leading, spacing: 18) {
                header
                searchField
                content
                footer
            }
            .padding(22)
        }
        .frame(width: 640, height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.10),
                            Color.blue.opacity(0.18),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 26, x: 0, y: 18)
        .onAppear {
            viewModel.refreshForPresentation()
            isSearchFocused = true
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.syncSelection()
        }
        .onExitCommand {
            onClose()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Clipboard History")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.96))

                Text(L("AquaPaste · Press Option + V to open. Use ↑ ↓ to select and Enter to paste.", "AquaPaste · Option + V để mở. Dùng ↑ ↓ để chọn và Enter để dán ngay."))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            if viewModel.canAutoPaste == false {
                GlassCapsuleLabel(
                    text: L("Enable Accessibility to auto-paste", "Cần bật Accessibility để tự dán"),
                    tint: Color.orange.opacity(0.85)
                )
            } else {
                GlassCapsuleLabel(
                    text: L("Auto-paste ready", "Tự dán đang sẵn sàng"),
                    tint: Color.green.opacity(0.80)
                )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.72))

            TextField(L("Search clipboard history...", "Tìm trong lịch sử clipboard..."), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .foregroundStyle(.white.opacity(0.94))
                .onSubmit {
                    if let item = viewModel.selectedItem() {
                        onSelect(item)
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.filteredItems.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.75))
                Text(L("No matching items", "Chưa có dữ liệu phù hợp"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                Text(L("Copy some text or images to build your history.", "Hãy copy thêm văn bản hoặc hình ảnh để xây dựng lịch sử."))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredItems) { item in
                        ClipboardRowView(
                            item: item,
                            isSelected: item.id == viewModel.selectedItemID,
                            onTap: {
                                viewModel.select(item)
                                onSelect(item)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(L("Close", "Đóng")) {
                onClose()
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(GlassActionButtonStyle(tint: .white.opacity(0.14)))

            Button(L("Clear History", "Xóa lịch sử"), role: .destructive) {
                viewModel.store.clear()
                viewModel.syncSelection()
            }
            .buttonStyle(GlassActionButtonStyle(tint: .red.opacity(0.22)))

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(L("\(viewModel.store.items.count) / \(viewModel.store.maxItems) items", "Đang có \(viewModel.store.items.count) / \(viewModel.store.maxItems) mục"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                Text(L("History is saved after you close the app", "Lịch sử được lưu lại sau khi đóng app"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }
        }
    }
}

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                preview

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        GlassTag(
                            text: item.kind == .text ? "Text" : "Image",
                            systemImage: item.kind == .text ? "text.alignleft" : "photo"
                        )

                        Spacer()

                        Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.54))
                    }

                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineLimit(2)

                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.17) : Color.white.opacity(0.08))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.30) : Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? Color.cyan.opacity(0.18) : Color.clear,
                radius: 16,
                x: 0,
                y: 10
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var preview: some View {
        if let image = item.imagePreview {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.35),
                            Color.blue.opacity(0.18),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
        }
    }
}

private struct GlassCapsuleLabel: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tint.opacity(0.22))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }
}

private struct GlassTag: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.74))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .background(.thinMaterial, in: Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct GlassActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.82 : 0.96))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 1 : 0.92))
                    .background(
                        .thinMaterial,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}
