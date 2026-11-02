# Logo được chọn từ Facebook — 31/10/2026

Logo hiện tại giữ nguyên ảnh đỏ/cam với chữ trắng “Hôm Nay Ăn Gì” và dấu hỏi
hình chiếc nĩa, theo trang người dùng chỉ định:
[Hôm Nay Ăn Gì trên Facebook](https://www.facebook.com/p/H%C3%B4m-Nay-%C4%82n-G%C3%AC-100068950842301/).

Ảnh được lưu từ kết quả Google Images trỏ đúng page ID `100068950842301`,
ảnh Facebook `482954370679587`. File tải được là PNG 447 × 447 px:
[facebook-logo-source.png](../assets/branding/facebook-logo-source.png).
SHA-256 `bfba2b8355792bf57472d5d0e63cc8ac884f7a78985054fbc5e17c50dfea6af8`.
File này được giữ nguyên byte; không vẽ lại chữ hoặc đổi màu.

## File bàn giao

- [Ảnh nguồn 447 px](../assets/branding/facebook-logo-source.png)
- [PNG 1024](../assets/branding/app-icon-1024.png) / [PNG 512](../assets/branding/app-icon-512.png)
- [Xem logo](../assets/branding/logo-preview.png)
- [Logo cùng tên ứng dụng](../assets/branding/wordmark.png)
- [Kiểm tra kích thước nhỏ](../assets/branding/small-size-preview.png)
- [Bộ logo PNG](../artifacts/hom_nay_an_gi-facebook-logo-kit.zip)

Các bản lớn hơn 447 px là ảnh nội suy từ nguồn hiện có, không phải vector hoặc
ảnh gốc độ phân giải cao. Bộ này không xuất SVG giả từ bitmap. Bản logo bát ăn
xanh trước đó được lưu riêng trong `artifacts/logo-previous-green/`.

## Áp dụng

- App dùng `BrandMark` với asset local, hoạt động offline, giữ đúng tỉ lệ vuông.
- Android: icon theo DPI và adaptive icon nền trắng, có khoảng trống an toàn để
  mặt nạ tròn không cắt chữ/nĩa. Không dùng layer monochrome của logo xanh cũ.
- iOS: AppIcon đúng từng slot, PNG RGB không alpha; LaunchImage 1x/2x/3x.
- Web: favicon và icon 192/512; bản maskable thêm khoảng trống an toàn.
- Giao diện ứng dụng tiếp tục dùng màu xanh/kem đã có.

Tái tạo kích thước bằng `flutter test tool/generate_icons.dart`. Script đọc
`facebook-logo-source.png`, không tải lại từ Facebook khi build.

Bản cài: [APK logo Facebook](../artifacts/hom_nay_an_gi-facebook-logo-debug.apk).
Ảnh Android: [launcher](../artifacts/facebook_logo_launcher_native.png),
[khởi động](../artifacts/facebook_logo_splash_native.png),
[đăng nhập](../artifacts/facebook_logo_login_native.png).
Ảnh giao diện mới nằm trong [design.md](design.md). Tình trạng kiểm thử và build
được ghi tại [verification.md](verification.md). Native iOS cần build/sign trên Mac.
