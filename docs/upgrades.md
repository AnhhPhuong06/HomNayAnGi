# Nâng cấp khẩu vị, bản đồ và sao lưu — 02/11/2026

## Khẩu vị cá nhân

Mở **Trang chủ → Khẩu vị** hoặc **Cài đặt → Khẩu vị của bạn**.
Chọn kiểu món muốn tránh, nhập tối đa 20 từ khóa cách nhau bằng dấu phẩy và chọn
tránh 3/5/10 lượt gợi ý gần nhất. Các thay đổi chỉ có hiệu lực khi bấm **Lưu khẩu vị**.

Các món/quán bị loại không được đưa lại khi nới ngân sách hoặc kiểu món. Từ khóa
được so không dấu với tên, mô tả và nhãn trong nguồn. Bộ lọc áp dụng cho trang chủ,
Khám phá và thuật toán gợi ý. Trang chi tiết vẫn mở được từ quán yêu thích/bài blog.
Có thể ẩn một quán ở trang chi tiết hoặc kết quả gợi ý, rồi bỏ ẩn trong hồ sơ khẩu vị.

Nếu mọi quán phù hợp đều nằm trong cửa sổ lịch sử, ứng dụng thông báo trước khi
chọn lại trong nhóm đó. Đây không phải lý do để đưa lại quán đã ẩn/món không thích.
Nguồn chưa có thành phần đầy đủ nên bộ lọc không xác nhận ăn chay hay an toàn dị ứng.

## Khám phá bằng bản đồ

Mở **Khám phá → Bản đồ**, chọn khu vực nếu chưa có. Các ghim dùng tọa độ thật từ
catalog OSM đang đóng gói, cùng bộ lọc với danh sách. Hiển thị tối đa 80 quán gần
khu vực đã chọn để giữ màn hình nhẹ. Chạm ghim để xem thẻ quán và mở chi tiết.
Có phóng to/thu nhỏ và nút về tâm khu vực.

Nền bản đồ tải từ `https://tile.openstreetmap.org/{z}/{x}/{y}.png`; không cần Google
Places API key. Chỉ mở tile layer khi chọn chế độ Bản đồ. Có attribution hiện thường
trực, User-Agent riêng, không tải hàng loạt/prefetch; dùng cache HTTP tích hợp của
flutter_map 8.3.2, giới hạn mềm 100 MB. Cache có thể bị hệ điều hành dọn.
Khi chưa tải được nền, ghim từ catalog và chế độ Danh sách vẫn dùng được.

Public tile server hoạt động best-effort, không phải dịch vụ miễn phí không giới hạn.
Trước khi triển khai lượng người dùng lớn cần đánh giá nguồn tile phù hợp. Có thể
cấu hình nguồn HTTPS khác bằng `--dart-define=MAP_TILE_URL=...` và cập nhật attribution
nếu đổi nguồn. `--dart-define=DISABLE_MAP_NETWORK=true` dùng cho kiểm thử ngoại tuyến.

Khi người dùng mở bản đồ, nhà cung cấp tile nhận IP và vùng bản đồ đang xem.
Ứng dụng không gửi bản sao GPS tới backend tài khoản; việc tải nền bản đồ là kết nối
riêng với nhà cung cấp tile. Đã cập nhật nội dung quyền riêng tư trong app.

## Dữ liệu theo tài khoản và sao lưu

Sau khi có backend và phiên đăng nhập thật, yêu thích, lịch sử, khẩu vị, bộ lọc và
khu vực trên máy được tách theo Firebase UID. Đổi tài khoản không kế thừa dữ liệu
của người trước. Dữ liệu cũ chưa phân tài khoản được giữ nguyên ở key cũ; người dùng
có thể chủ động chọn **Nhập dữ liệu từ phiên bản cũ trên máy** trong Cài đặt.

**Lưu lên tài khoản / Khôi phục từ tài khoản** là thao tác thủ công. Chỉ sao lưu
yêu thích (tối đa 1.000), lịch sử (20), bộ lọc và khẩu vị; không sao lưu GPS, khu vực,
giao diện, email hoặc mật khẩu. Có xác nhận trước khi thay bản cloud/khôi phục.
Khôi phục giữ nguyên khu vực và giao diện hiện tại trên máy.

Bản sao lưu nằm ở `profiles/{uid}`, chỉ chủ UID được đọc/ghi/xóa. Firestore rules
chặn schema ngoài danh sách cho phép, vị trí trong payload, lịch sử quá dài và
revision sai. Transaction dùng revision để chặn ghi đè nếu thiết bị khác đã thay
bản sao lưu trong lúc xác nhận. Transaction cần mạng; không dùng set() xếp hàng
ngoại tuyến cho thao tác sao lưu. Không báo thành công trước khi server xác nhận.

Đổi tài khoản giữa lúc khôi phục không áp dữ liệu cho tài khoản mới. Gợi ý trả về
trễ cũng không xuất hiện ở tài khoản kế tiếp. Xóa/đăng xuất và sao lưu dùng khóa
thao tác chung để không chạy chồng. Xóa tài khoản có xóa bản cloud và dữ liệu local
của UID đó; dữ liệu của tài khoản khác và key cũ được giữ.

Cần deploy bản `firestore.rules` mới cùng cấu hình Auth/provider theo
[community.md](community.md). Chưa deploy Firebase hay xác minh OAuth thật vì chưa
có project/provider của người dùng. Bản shipping tiếp tục yêu cầu đăng nhập;
không thêm tài khoản giả hoặc lối đi qua màn đăng nhập.

## Xem trước và kiểm tra

- [Khẩu vị](../artifacts/upgrade_taste_fixture.png)
- [Sao lưu trong Cài đặt](../artifacts/upgrade_settings_fixture.png)
- [Bản đồ khi tắt mạng](../artifacts/upgrade_map_offline_fixture.png)
- Android API 36: [khẩu vị](../artifacts/upgrade_taste_native_fixture.png),
  [bản đồ](../artifacts/upgrade_map_native_fixture.png),
  [cài đặt](../artifacts/upgrade_settings_native_fixture.png).

Ảnh có hậu tố `fixture` dùng phiên kiểm thử và catalog thật, không phải phiên OAuth
production. Các nút cloud trong ảnh không chứng minh đã kết nối backend thật.
Chi tiết kết quả kiểm thử và artifact: [verification.md](verification.md).

Integration test Android đã đạt. Kết nối máy chủ tile bị reset trong lượt thử;
ảnh native xác nhận giao diện khi lỗi mạng và ghim catalog, chưa xác nhận nền
bản đồ online tải thành công. Ba ảnh tính năng native được xuất từ lượt
integration test đã đạt; ảnh đăng nhập chụp trực tiếp từ APK shipping bằng ADB.

Tái tạo ảnh widget:

```bash
flutter test test/visual/preview_ui_test.dart --dart-define=RENDER_UI_PREVIEWS=true --no-pub --concurrency=1
```

Kiểm thử Android với ảnh native, phiên test riêng và catalog thật:

```bash
flutter drive --driver=test_driver/upgrade_driver.dart --target=integration_test/upgrade_flow_test.dart -d emulator-5554
```

Test này dùng tọa độ địa điểm công khai ở trung tâm TP.HCM, không phải GPS người dùng.
Native iOS cần build/run/sign trên Mac; môi trường hiện tại là Windows.

Nguồn kỹ thuật:
[flutter_map](https://docs.fleaflet.dev/),
[tile caching](https://docs.fleaflet.dev/layers/raster-tile-layer/caching),
[OSM tile policy](https://operations.osmfoundation.org/policies/tiles/),
[Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions).
