# Mở Hôm Nay Ăn Gì trong Xcode

## GitHub Actions: IPA chưa ký

Workflow `.github/workflows/ios-unsigned.yml` chạy trên `macos-15-intel` và
chọn Xcode 26.3 bằng `DEVELOPER_DIR`. Không dùng Xcode 16.4 mặc định của image:
Xcode 26.3 đáp ứng toolchain được Firebase hỗ trợ.

Các gói được khóa ở `firebase_core 4.15.2`, `firebase_auth 6.7.1` và
`cloud_firestore 6.10.2`, dùng Firebase iOS SDK **12.19.3** đã vá bảo mật.
Google Sign-In iOS 9.x yêu cầu GTMSessionFetcher 3.x; Firebase 12.19.3 chấp nhận
`3.4.1..<6.0.0`, nên hai SDK có thể dùng chung bản 3.x.
Firebase 13 yêu cầu từ 4.x và [chưa có Google Sign-In tương thích qua SPM](https://github.com/firebase/firebase-ios-sdk/blob/main/FirebaseCore/CHANGELOG.md).
Không nâng riêng từng gói FlutterFire lên nhánh Firebase 13 cho tới khi có SDK
Google Sign-In tương thích. Bản vá 12.19.3 được ghi trong
[changelog FlutterFire](https://pub.dev/packages/firebase_core/versions/4.15.2/changelog).
Workflow in phiên bản Xcode/Swift trước khi giải dependency để thấy rõ toolchain.
Chạy **Actions → Build unsigned IPA → Run workflow → main**. Khi thành công,
artifact `hom_nay_an_gi-unsigned` chứa IPA chưa ký; cần ký lại trước khi cài.

Để tài khoản hoạt động, trước khi chạy workflow hãy làm theo
[Firebase Spark / Google và GitHub Secret](firebase-free-setup.md). Chế độ mặc
định `configured` yêu cầu secret `FIREBASE_IOS_CONFIG_JSON`, tạo cấu hình native
và truyền JSON vào Dart. `compile-only` dành riêng cho kiểm tra biên dịch, vẫn
hiển thị dịch vụ tài khoản chưa sẵn sàng.

## Project nguồn trên Mac

Bản build có cấu hình Google đã thành công ngày 04/11/2026 tại
[run 41783504670](https://github.com/AnhhPhuong06/HomNayAnGi/actions/runs/41783504670)
(commit `1fb4165`). Đã kiểm tra callback và cấu hình được nhúng trong IPA;
chưa thử OAuth trên iPhone. [Bằng chứng và giới hạn](verification.md).
Gói ZIP mã nguồn không chứa cấu hình tài khoản riêng. Khi build từ ZIP ở máy
khác, cần thiết lập lại theo [hướng dẫn Firebase](firebase-free-setup.md).

Gói hiện tại có [UX/UI thích ứng, cá nhân hóa và địa điểm cộng đồng](adaptive-community.md).

Gói `hom_nay_an_gi-xcode.zip` chứa workspace iOS, mã Dart, assets và catalog
18.668 địa điểm OSM đang dùng trong app. Giữ nguyên cả thư mục sau giải nén;
workspace cần mã Flutter và assets nằm ngoài `ios/`.

Bản 02/11/2026 gồm hồ sơ khẩu vị, ẩn quán, giảm lặp gợi ý, bản đồ OSM và
sao lưu/khôi phục thủ công theo tài khoản. [Cách dùng và giới hạn](upgrades.md).

Bản cập nhật có đăng nhập Google/Facebook/Apple bắt buộc và blog dùng Firebase.
Trước khi chạy tài khoản thật, làm theo [community.md](community.md), tạo
`config/firebase.ios.json` và `ios/Flutter/Social.xcconfig`. Script mở Xcode nhận
`--dart-define-from-file=config/firebase.ios.json`. Nếu không cấu hình, app hiển thị
màn hình đăng nhập với thông báo dịch vụ chưa sẵn sàng.

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

Đã build iOS Release không ký bằng Xcode 26.3 trên GitHub Actions ngày 02/11/2026:
[run 41443870844](https://github.com/AnhhPhuong06/HomNayAnGi/actions/runs/41443870844),
commit mã ứng dụng `833ff41`. Analyze và 95 bài kiểm thử đạt.
IPA arm64 `1.0.0+1` (iOS 15.0+) đã kiểm tra ZIP CRC, bundle identifier,
catalog/logo khớp nguồn và không có chữ ký ứng dụng/provisioning profile.
SHA-256: `6f3b092889265f7d9ef25828271a5ace8965da6edae40437dc3df25d1d728f85`.
**Chưa chạy iOS Simulator/thiết bị thật hoặc kiểm thử OAuth iOS.**
IPA chưa ký cần được ký lại trước khi cài; vẫn cần cấu hình Firebase/các nhà cung cấp.
