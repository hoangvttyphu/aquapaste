# AquaPaste

**Đọc bằng ngôn ngữ khác: [English](README.md)**

**Win + V cho MacBook.** AquaPaste là app macOS nhỏ gọn, miễn phí, mô phỏng tính năng **Clipboard History (Lịch sử bảng tạm)** quen thuộc trên Windows. Thay vì chỉ dán được nội dung sao chép cuối cùng, bạn xem lại và dán bất kỳ thứ gì đã copy trước đó (văn bản và hình ảnh).

Mở bảng lịch sử bằng phím tắt **`Option + V`**.

> App do Vi Tiến Hoàng (hoang.com.vn) tự viết cho nhu cầu cá nhân rồi chia sẻ miễn phí. Mã nguồn mở, dùng thoải mái.

Giao diện **mặc định tiếng Anh** và **tự chuyển sang tiếng Việt** khi máy đặt ngôn ngữ tiếng Việt.

## Tính năng

- Theo dõi mọi thứ bạn copy: **văn bản** và **hình ảnh**.
- Mở panel lịch sử bằng `Option + V`, ở bất kỳ app nào.
- Điều hướng bằng bàn phím: `↑` `↓` để chọn, `Enter` để dán, `Esc` để đóng.
- Chọn một mục sẽ **tự copy lại và tự dán** vào app đang làm việc (khi đã cấp quyền Accessibility).
- Giao diện **Liquid Glass** kính mờ nhiều lớp theo đúng ngôn ngữ thiết kế của macOS.
- Icon trên **menu bar** để mở nhanh, xóa lịch sử, hoặc thoát app.
- **Lưu bền vững**: giữ 50 mục gần nhất, còn nguyên sau khi tắt máy.
- Nhẹ (~550 KB), chạy nền, không thu thập dữ liệu, không gửi gì lên mạng.

Yêu cầu: **macOS 13 trở lên** (Ventura, Sonoma, Sequoia, Tahoe...), cả máy Apple Silicon.

## Cách cài (bản chạy ngay)

1. Tải file `AquaPaste.zip` từ [bản phát hành mới nhất](https://github.com/hoangvttyphu/aquapaste/releases/latest) về, giải nén sẽ ra **`AquaPaste.app`**.
2. Kéo `AquaPaste.app` vào thư mục **Applications**.
3. **Lần đầu mở:** vì app chưa mua chứng chỉ nhà phát triển của Apple, macOS sẽ chặn. Bạn **bấm chuột phải vào `AquaPaste.app` → chọn `Open` → bấm `Open` lần nữa**. Chỉ cần làm một lần duy nhất.
   - Nếu vẫn báo "app bị hỏng / không mở được", mở **Terminal** và chạy:
     ```bash
     xattr -cr /Applications/AquaPaste.app
     ```
     rồi mở lại app.
4. App chạy nền, hiện icon bảng tạm trên **menu bar** (góc phải trên màn hình). Không có cửa sổ chính.

## Cấp quyền để tự dán

Để AquaPaste tự bấm `Cmd + V` giúp bạn sau khi chọn một mục, macOS cần quyền Accessibility:

**System Settings → Privacy & Security → Accessibility → bật công tắc cho AquaPaste.**

Nếu chưa cấp quyền, app vẫn hoạt động: nó copy nội dung bạn chọn vào clipboard, bạn chỉ cần tự bấm `Cmd + V`.

## Cách dùng

1. Copy vài thứ như bình thường (`Cmd + C`).
2. Nhấn **`Option + V`** để mở bảng lịch sử.
3. Dùng `↑` `↓` chọn mục cần, nhấn `Enter` (hoặc bấm chuột) để dán lại.
4. `Esc` để đóng bảng mà không dán.

Menu bar còn có: **Mở AquaPaste**, **Xóa lịch sử**, **Thoát**.

## Dữ liệu lưu ở đâu

Lịch sử lưu tại:

```
~/Library/Application Support/AquaPaste/clipboard-history.json
```

App giữ tối đa **50 mục gần nhất**. Khi vượt 50, mục cũ nhất bị bỏ, file được ghi đè theo kiểu atomic (an toàn, không sinh file rác). Toàn bộ dữ liệu nằm trên máy bạn, không gửi đi đâu.

## Tự build từ mã nguồn (cho lập trình viên)

Máy cần **Xcode Command Line Tools** và **Swift 6+**.

```bash
# chạy trực tiếp
swift run AquaPaste

# hoặc đóng gói thành .app
chmod +x scripts/build-app.sh
./scripts/build-app.sh release
open dist/AquaPaste.app

# cài vào Applications
chmod +x scripts/install-app.sh
./scripts/install-app.sh
```

Kiến trúc chính:

- `ClipboardStore.swift` — theo dõi pasteboard, lưu/đọc lịch sử, atomic write.
- `ClipboardHistoryAppDelegate.swift` — vòng đời app, menu bar, điều phối phím tắt và dán.
- `GlobalHotKeyMonitor.swift` — đăng ký hotkey toàn cục `Option + V` qua Carbon.
- `ClipboardPanelView.swift` + `LiquidGlassBackground.swift` — giao diện kính mờ và điều hướng bàn phím.
- `PasteAutomation.swift` — tự bấm `Cmd + V` vào app trước đó qua Accessibility.
- `Localization.swift` — tự đổi Anh/Việt theo ngôn ngữ máy.

## Giấy phép

MIT License — xem file [LICENSE](LICENSE). Dùng, sửa, chia sẻ tự do.
