# UX/UI thích ứng và địa điểm cộng đồng — 02/11/2026

## Bố cục và chuyển động

App dùng chiều rộng cửa sổ để chọn bố cục. Điện thoại có điều hướng dưới;
từ 720 px dùng thanh bên cuộn được. Cửa sổ ngang rộng từ 600 px, cao 300–479 px
cũng dùng thanh bên. Thanh bên mở rộng nhãn khi đủ chỗ, không ép mọi thiết bị
dùng cùng một cỡ giao diện.

Trang chủ, Khám phá, Yêu thích và Blog có vùng nội dung tối đa 1.120 px.
Thẻ tự xếp 1–3 cột, chiều cao theo nội dung. Chữ lớn làm giảm số cột.
Biểu mẫu/sheet tối đa 720 px; sheet mở trên thanh điều hướng. Thông báo trống
cuộn được khi màn hình thấp hoặc chữ rất lớn. Đổi kích thước giữ tab/tìm kiếm.

Chuyển trang Android dùng fade/dịch nhẹ 220 ms; iOS giữ chuyển trang và quay
lại Cupertino. Tim yêu thích chuyển 160 ms, chỉ dựng lại vùng biểu tượng.
Hiệu ứng chọn món giảm từ 1,1 giây xuống 600 ms, chạy cùng phép tính gợi ý.
Giảm chuyển động bỏ các hiệu ứng này và đổi theme; luôn tôn trọng Android
Remove animations và iOS Reduce Motion. Chưa đo FPS trên thiết bị thật ở
profile/release, không cam kết tốc độ khung hình cho mọi thiết bị.

## Cá nhân hóa

Trong **Cài đặt → Giao diện** có sáng/tối/theo hệ thống, ba màu xanh rừng/đại
dương/dâu tím, chữ hệ thống/lớn thêm 15%/30%, thẻ quán gọn và giảm chuyển động.
Cỡ chữ nhân trên scaler hệ thống, không giới hạn chữ trợ năng. Tùy chọn lưu
trên thiết bị theo UID khi có phiên thật; không nằm trong backup cloud.
Khôi phục yêu thích/khẩu vị không đổi giao diện. Giữ nguyên logo Facebook.

## Chia sẻ địa điểm mới

Mở **Blog → Thêm địa điểm mới**, hoặc **Khám phá → Cộng đồng**. Nhập tiêu đề,
nội dung, tên quán, địa chỉ và ghim quán. Có thể chạm bản đồ để chọn ghim hoặc
nhập hai tọa độ; kiểm tra số hữu hạn, vĩ độ ±90 và kinh độ ±180. Không tự điền
hay tự đăng GPS. Khu vực hiện tại có thể làm tâm bản đồ, nhưng chưa được chọn
làm ghim cho đến khi người dùng chủ động chọn.

Sau khi đồng ý quy tắc và đăng, tên hiển thị, địa chỉ, nội dung và ghim được
chia sẻ với các thành viên đã đăng nhập. Không có đăng ẩn danh hay upload ảnh
mới. Ảnh món đi kèm vẫn được ghi rõ là ảnh minh họa.

Địa điểm hiện ở Blog và mục Cộng đồng của Khám phá, có tìm tên/địa chỉ/tiêu đề,
chỉ đường, xóa bài của mình, báo cáo và chặn tác giả. Nguồn được ghi rõ do
thành viên chia sẻ, chưa xác minh. Mục này lấy địa điểm từ **30 bài mới nhất**,
chưa phải danh mục phân trang đầy đủ. Bộ lọc OSM không áp dụng ở đây; bài mới
không được trộn vào catalog OSM ngoại tuyến. Khi nền bản đồ lỗi vẫn nhập
tọa độ được. [Nguồn tile, cache và giới hạn](upgrades.md).

Firestore dùng `posts/{id}`, `kind: place`, thêm `latitude`/`longitude`.
Rules chặn anonymous, giả UID, thiếu/sai tọa độ, gán ID OSM cho địa điểm mới
và tọa độ trong bài thông thường. Chỉ chủ bài được xóa; không cho sửa bài.
Luồng xóa tài khoản xóa cả bài địa điểm. Sao lưu, đăng xuất/xóa tài khoản và
ghi bài dùng khóa thao tác chung.

**Cần deploy rules mới và cấu hình Firebase/provider** theo [community.md](community.md).
Chưa deploy hay xác minh hai tài khoản production vì người dùng chưa có cấu
hình. Bản shipping tiếp tục yêu cầu đăng nhập, không có lối vào bằng phiên giả.
Khi chọn ghim, nhà cung cấp tile nhận IP/vùng xem; tọa độ quán chỉ gửi tới
Firestore khi chủ động đăng. Quyền riêng tư trong app đã cập nhật.

## Tệp và ảnh kiểm tra

- [APK cài thử](../artifacts/hom_nay_an_gi-adaptive-debug.apk)
- [Project Xcode](../artifacts/hom_nay_an_gi-xcode.zip)
- [Kết quả kiểm tra](verification.md)
- Ảnh [tablet](../artifacts/adaptive_tablet_discover_fixture.png),
  [màn hình lớn](../artifacts/adaptive_desktop_home_fixture.png),
  [cá nhân hóa](../artifacts/adaptive_personalization_fixture.png),
  [địa điểm cộng đồng](../artifacts/adaptive_community_places_fixture.png),
  [biểu mẫu](../artifacts/adaptive_place_form_fixture.png).

Ảnh `fixture` dùng phiên/bài kiểm thử và catalog thật; không chứng minh OAuth
hay bài đăng production. Native iOS cần build/run/sign trên Mac. Chưa bổ sung
runner desktop; kiểm tra bố cục màn hình lớn không có nghĩa đã phát hành desktop.

Integration test Android API 36 đã đạt: lưu màu và đăng/xem bài địa điểm trong
phiên fixture. Ảnh [cá nhân hóa native](../artifacts/adaptive_personalization_native_fixture.png),
[biểu mẫu native](../artifacts/adaptive_place_form_native_fixture.png),
[địa điểm native](../artifacts/adaptive_places_native_fixture.png).
Bản chính đã kiểm tra [màn đăng nhập](../artifacts/adaptive_login_native.png).

```bash
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter test test/visual/preview_ui_test.dart --dart-define=RENDER_UI_PREVIEWS=true --no-pub --concurrency=1
```

Nguồn kỹ thuật: [Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices),
[disableAnimations](https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html).
