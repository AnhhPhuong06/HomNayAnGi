# Xác minh MVP — 30/10/2026

Đây là báo cáo baseline của MVP dùng demo trước khi thêm catalog OSM. Quy trình
và giới hạn nguồn thật hiện tại xem [open-data.md](open-data.md); số lượng và
snapshot hiện tại nằm trong `assets/data/catalog_manifest.json`.

## Môi trường

- Windows 11, Flutter Stable 3.47.9, Dart 3.13.7, JDK 21.
- Android SDK 36, NDK 28.2.13676358, CMake 3.22.1.
- Android emulator API 36, x86_64, WHPX; Wi-Fi và mobile data tắt trong các bài integration.
- `flutter doctor -v`: Flutter, Android toolchain và thiết bị Android đạt. Chrome chưa cài, không cản phát triển Android; Edge có sẵn.

## Kết quả đã chạy

- `flutter analyze`: **No issues found**.
- `dart format --output=none --set-exit-if-changed lib test integration_test tool/generate_icons.dart`: không có file cần format.
- `flutter test`: **42 tests pass** (32 unit/controller/persistence + 10 widget).
- `flutter build apk --debug`: thành công với Android target.
- `integration_test/core_flow_test.dart`: pass trên emulator offline. Chọn khu vực → chọn món → yêu thích → chi tiết → tìm không dấu → dark mode → khởi tạo lại widget tree từ platform storage.
- `integration_test/location_denied_test.dart`: pass với quyền fine/coarse bị revoke và đặt `user-fixed`. App hiển thị trạng thái quyền bị khóa và chọn khu vực thủ công vẫn hoạt động.
- `integration_test/location_gps_test.dart`: pass với quyền foreground được grant và tọa độ **demo** cung cấp bằng `adb emu geo fix`. App dùng Android LocationManager, không cần bật Google Location Accuracy hoặc Wi-Fi scanning.
- Đọc file SharedPreferences native sau bài GPS: trường location là `null`; fix GPS chính xác không được persist.
- Cài APK `main.dart` rồi force-stop/mở lại ở mức OS (`LaunchState: COLD`): đọc lại native preferences xác nhận dark theme, một quán yêu thích, lịch sử và khu vực thủ công được giữ. Kiểm tra trực quan Home/Yêu thích sau cold restart không có lỗi layout.
- Kiểm tra merged Android manifest: không có quyền background location, camera, microphone, contacts hay photos; backup Android bị tắt.
- Bấm Chỉ đường trên quán demo, xác nhận lời nhắc: Android mở `com.google.android.apps.maps` bằng VIEW intent với URL HTTPS và tọa độ đích đúng. Chỉ xác minh việc chuyển sang Maps; không tuyên bố tải được tuyến đường khi emulator đang offline.

## Những sửa chữa từ kiểm thử thực tế

- Kotlin incremental cache không hỗ trợ relative path giữa Pub cache ổ C: và project ổ D:. Tắt riêng Kotlin incremental compilation; không hạ package, không tắt lint/test.
- Fused Location của Google trên emulator offline đưa ra hộp thoại bật Location Accuracy/Wi-Fi scanning. Chuyển yêu cầu GPS một lần sang Android LocationManager với timeout để hoạt động offline và giảm yêu cầu dữ liệu ngoài scope.
- Flutter Test `pageBack()` tìm tooltip tiếng Anh; integration test của app tiếng Việt tìm `BackButton` trực tiếp.
- Dùng `--no-uninstall` khi cần giữ dữ liệu qua các lượt test/cold restart; Flutter Test mặc định gỡ test app khi kết thúc.

## Giới hạn đã biết

- Dữ liệu quán **DEMO**, ảnh minh họa đi kèm, chưa phải nguồn production đã xác minh. Không cần API key và không gọi restaurant API.
- Chưa build/sign/test native iOS vì môi trường Windows. Có scaffold iOS, usage description When In Use và script archive cho macOS/Xcode.
- Chưa kiểm tra trên máy Android vật lý hoặc đo performance release. Kết quả emulator/debug không phải benchmark production.
- Cold launch debug quan sát được khoảng 11–14 giây trên emulator này; một lượt `am start -W` timeout nhưng kiểm tra sau đó xác nhận Home đã render và activity vẫn RESUMED. Cần đo bản release trên thiết bị thật trước khi cam kết mục tiêu startup production.
- Chưa phát hành cửa hàng. APK bàn giao là debug để cài thử. Release dùng keystore riêng; không có cấu hình ký release bằng debug key.
- Remote provider, remote cache và debounce/cancel request phía server được mô tả tại README để triển khai khi có nguồn dữ liệu; không giả lập chúng như chức năng production đã tích hợp.

## Artifact trên máy triển khai

- APK cài thử: `artifacts/hom_nay_an_gi-debug.apk` (234.685.125 bytes, universal debug, entry point `lib/main.dart`).
- SHA-256: `F77C60E25336B2DCEB7A7D141BD4267EFFA50F3E4C835006EF7DD077CD509806`.
- `artifacts/home_dark_after_restart.png`: Home với theme và khu vực được restore.
- `artifacts/favorites_after_restart.png`: quán yêu thích vẫn còn sau cold restart, ảnh demo hiển thị khi offline.

Artifact nằm local, không được commit Git; tạo lại APK bằng lệnh trong README. APK debug không dùng để đánh giá kích thước/performance release.
