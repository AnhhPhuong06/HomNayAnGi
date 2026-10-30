# Mở Hôm Nay Ăn Gì trong Xcode

Gói `hom_nay_an_gi-xcode.zip` chứa workspace iOS, mã Dart, assets và catalog
18.668 địa điểm OSM đang dùng trong app. Giữ nguyên cả thư mục sau giải nén;
workspace cần mã Flutter và assets nằm ngoài `ios/`.

## Mở trên Mac

1. Cài Flutter Stable **3.47.9** và Xcode; cấu hình command-line tools, chấp nhận
   license và tải iOS platform theo [hướng dẫn Flutter chính thức](https://docs.flutter.dev/platform-integration/ios/setup).
   Chạy `flutter doctor -v` để kiểm tra môi trường. Project đặt iOS deployment
   target **15.0** và dùng Swift Package Manager.
2. Giải nén ZIP trên Mac. Mở Terminal tại thư mục `hom_nay_an_gi_xcode` vừa giải nén.
3. Thoát Xcode nếu đang mở, rồi chạy:

   ```bash
   bash ios/open_xcode.sh
   ```

   Script tải dependency theo lockfile, tạo cấu hình/đường dẫn SDK cho máy Mac
   bằng `flutter build ios --debug --config-only --no-codesign`, sau đó mở
   `ios/Runner.xcworkspace`. Lần chuẩn bị đầu cần Internet để tải SDK/dependency.
4. Trong Xcode, chọn scheme **Runner**, chọn một iOS Simulator đã cài và nhấn
   **Run**. Để chạy iPhone thật, vào **Runner → Signing & Capabilities**, chọn
   Team của bạn và bundle identifier phù hợp.

Nếu dùng Xcode được cài ở vị trí khác, chọn đúng bản bằng `xcode-select` trước.
Script mở Xcode trực tiếp để môi trường resolve/build Swift package giữ
`BYPASS_PERMISSION_LOCATION_ALWAYS=1` cho geolocator Apple 2.4.3. App chỉ xin vị
trí khi sử dụng; `Info.plist` có mô tả tiếng Việt, không có background location.

## Archive / IPA

Sau khi cấu hình signing trên Mac:

```bash
bash ios/build_ios.sh --release
```

Có thể dùng **Product → Archive** trong phiên Xcode do script trên mở.
Quy trình signing và xuất IPA theo [tài liệu Flutter](https://docs.flutter.dev/deployment/ios).
Không có certificate, provisioning profile hay Apple account trong ZIP.

## Dữ liệu và kiểm tra

Catalog thật là mặc định, không cần Places API key. Giá/đánh giá/ảnh thiếu được
giữ trống. Google Maps mở chỉ đường; TikTok mở tìm kiếm hoặc link nguồn nếu có.
Attribution/ODbL và cách cập nhật nằm trong [open-data.md](open-data.md).

Gói không chứa cache Windows, `Generated.xcconfig`, Swift package sinh tự động,
Pods, build output hoặc SDK máy phát triển. Các file phụ thuộc máy được tạo lại
qua script trên Mac. Xem `EXPORT_MANIFEST.json` trong ZIP để đối chiếu checksum.

Đã kiểm tra cấu trúc ZIP, XML/plist, script Bash và catalog đóng gói trên Windows.
**Chưa biên dịch, chạy simulator hoặc ký iOS** vì máy xuất không có macOS/Xcode.
