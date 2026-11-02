# Giao diện hiện đại — 31/10/2026

Bản mới có [bố cục thích ứng, cá nhân hóa và địa điểm cộng đồng](adaptive-community.md).

Bản nâng cấp 02/11 thêm hồ sơ khẩu vị, bản đồ và thao tác sao lưu tài khoản.
Xem [upgrades.md](upgrades.md) để dùng tính năng và xem ảnh mới.

Giao diện mới dùng xanh rừng, kem và xanh nhạt; chữ Be Vietnam Pro, ảnh món lớn,
thẻ bo góc và thanh điều hướng nổi. Font được đóng gói offline, kèm giấy phép
tại `assets/fonts/OFL.txt`; nguồn ghi trong `assets/fonts/CREDITS.md`.

## Những màn hình được nâng cấp

- Đăng nhập: nhận diện ứng dụng, ảnh bìa món ăn, nút nhà cung cấp và thông báo
  trạng thái dịch vụ có thứ bậc rõ. Có cả giao diện sáng/tối.
- Trang chủ: thẻ chọn món bằng ảnh, bộ lọc nhanh và danh mục món cuộn ngang có
  trạng thái chọn. Khu vực, bộ lọc và thuật toán gợi ý vẫn dùng dữ liệu hiện có.
- Khám phá/yêu thích: tiêu đề, tìm kiếm và danh sách quán cùng hệ thống thẻ ảnh.
- Thẻ quán: ảnh bo góc, danh mục, nút lưu, địa chỉ, khoảng cách và thông tin giá.
  Giá/đánh giá thiếu tiếp tục được ghi rõ.
- Blog: phần đầu và danh sách cùng cuộn, hỗ trợ màn hình ngang/cỡ chữ lớn.
  Thẻ bài có tác giả, loại chia sẻ, ảnh minh họa và địa điểm đính kèm.
- Màn kết quả, chi tiết, form và cài đặt thừa hưởng font, màu, nút và khoảng cách.

Đăng nhập bắt buộc và quyền Firestore được giữ nguyên. Backend chưa được kết nối
vì chưa có project/provider; xem [community.md](community.md). Ảnh minh họa không
được nhận là ảnh quán thật. Không thêm rating, số lượt thích hay bài cộng đồng giả.

## Xem trước

- [Đăng nhập sáng](../artifacts/modern_login_light.png)
- [Đăng nhập tối](../artifacts/modern_login_dark.png)
- [Trang chủ](../artifacts/modern_home_fixture.png)
- [Blog trống](../artifacts/modern_blog_empty_fixture.png)
- [Khám phá](../artifacts/modern_discover_fixture.png)
- [Bản cài Android với logo Facebook](../artifacts/facebook_logo_login_native.png)

Ảnh được render từ chính widget Flutter. Các ảnh có hậu tố `fixture` dùng phiên
đăng nhập kiểm thử và catalog OSM thật; không phải ảnh một backend cộng đồng đang
hoạt động. Blog được giữ trống. Ảnh đăng nhập thể hiện trạng thái chưa cấu hình.
Các ảnh xem trước này cũng được kèm trong ZIP Xcode để xem trước khi cấu hình
dịch vụ đăng nhập.

## Kiểm tra và tái tạo

`flutter analyze` không có vấn đề; 63 unit/widget tests đạt, gồm luồng cũ, cỡ chữ
lớn và blog ngang. 5 bài xuất ảnh là tiện ích tùy chọn, được chạy riêng bằng:

```bash
flutter test test/visual/preview_ui_test.dart --dart-define=RENDER_UI_PREVIEWS=true --concurrency=1
```

Trong suite mặc định, 5 bài này được đánh dấu skip để không tạo ảnh ngoài ý muốn.
Phần kiểm tra tài khoản/blog dùng repository kiểm thử; không tuyên bố OAuth thật
đã hoạt động. Native iOS vẫn cần kiểm tra/build/ký trên Mac.

APK `hom_nay_an_gi-modern-debug.apk` đã build và được cài/mở trên Android API 36.
Đã kiểm tra trực quan font, ảnh, ba nút đăng nhập và trạng thái chưa cấu hình.

Bản logo Facebook hiện tại: `hom_nay_an_gi-facebook-logo-debug.apk`, đã cài/mở
trên Android API 36 và kiểm tra launcher, splash, logo ở màn đăng nhập. Các ảnh
widget phía trên đã được xuất lại với logo được chọn; xem [branding.md](branding.md).
