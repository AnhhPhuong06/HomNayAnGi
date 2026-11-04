# Xác minh MVP — 30/10/2026

Đây là báo cáo baseline của MVP dùng demo trước khi thêm catalog OSM. Quy trình
và giới hạn nguồn thật hiện tại xem [open-data.md](open-data.md); số lượng và
snapshot hiện tại nằm trong `assets/data/catalog_manifest.json`.

## Ảnh thật tại quán — 04/11/2026

- Đã đóng gói 9 ảnh Wikimedia Commons cho 9 địa điểm trong catalog 18.668 quán.
  Đối chiếu tên/địa chỉ/chi nhánh, lưu tác giả, giấy phép, ngày chụp, nguồn và SHA-256.
  Ảnh không bao phủ toàn bộ catalog; một số ảnh lịch sử khá cũ, không xác nhận
  diện mạo/tình trạng hoạt động hiện nay. [Phạm vi và cập nhật](open-data.md).
- Danh sách, kết quả gợi ý và chi tiết ưu tiên ảnh thật. Khám phá có bộ lọc
  **Có ảnh tại quán**; chạm attribution để xem nguồn, ngày chụp và giấy phép.
  Quán chưa có ảnh vẫn ghi rõ ảnh món ăn minh họa. OSM ID đổi tên doanh nghiệp
  không tự kế thừa ảnh cũ.
- Analyze không có vấn đề, 102 bài kiểm thử ứng dụng và 6 bài kiểm thử dữ liệu đạt.
  Có kiểm tra nguồn/giấy phép/path không an toàn, checksum assets, đổi tên quán,
  lọc ảnh và nguồn ảnh trên màn hình 320×568 với chữ phóng 2,6 lần.
- Ba bản xem trước dùng widget thật và ảnh thật, không phải bằng chứng native/OAuth:
  [chi tiết](../artifacts/real_photo_detail_fixture.png),
  [danh sách](../artifacts/real_photo_discover_fixture.png),
  [nguồn ảnh](../artifacts/real_photo_credit_fixture.png).
- [Run 41824359107](https://github.com/AnhhPhuong06/HomNayAnGi/actions/runs/41824359107)
  build iOS Release không ký thành công commit `df9099c`, giữ cấu hình Google.
  IPA 24.083.934 bytes, arm64, iOS 15.0+, bản `1.0.0+1`. Đã đối chiếu đủ 9 ảnh,
  CREDITS/manifest ảnh và catalog/logo trong IPA với nguồn; kiểm tra ZIP CRC,
  callback Google và cấu hình Firebase/Google trong binary đều đạt.
  SHA-256: `47045bd754c48475a267ce75302c51947ed278cf69b97c06a82dc315546cb203`.
  Chưa chạy bản ảnh mới trên iPhone/Simulator và chưa xác minh OAuth iOS thực tế.

## iOS có cấu hình Google/Firebase — 04/11/2026

- Đã đăng ký app iOS đúng bundle ID, xác nhận Google provider Enabled trên
  Firebase và project vẫn dùng Spark. Cấu hình riêng được lưu vào GitHub Secret;
  không đưa plist/JSON thật vào source hoặc gói ZIP mã nguồn.
- [Run 41783504670](https://github.com/AnhhPhuong06/HomNayAnGi/actions/runs/41783504670)
  build thành công commit `1fb4165` ở chế độ `configured`, dùng Xcode 26.3.
  Sáu bài kiểm tra script, analyze và 95 bài kiểm thử ứng dụng đạt.
- IPA 22.162.379 bytes, arm64, iOS 15.0+, bản `1.0.0+1`. Đã kiểm tra cấu hình
  Firebase/app ID/API key/Google client ID hiện diện trong binary AOT và URL
  callback Google khớp cấu hình; logo/catalog khớp nguồn và ZIP CRC đạt.
  Không có chữ ký ứng dụng hoặc provisioning profile.
  SHA-256: `1db010b0005412e73978027702499eb76cd0e73167c9ad1d41f6705106b0060a`.
- Chưa xác minh OAuth trên iPhone/Simulator. Cần ký và cài IPA mới để thử Google;
  IPA cũ chưa có cấu hình không tự cập nhật. Facebook/Apple và Firestore/rules
  chưa được cấu hình/triển khai trong lượt thiết lập Google này.

## Chuẩn bị cấu hình tài khoản iOS — 02/11/2026

- Thêm script nhập plist Firebase và tạo cấu hình Dart/native; không in giá trị.
  Sáu bài kiểm tra đạt, gồm thiếu secret, sai bundle/project, placeholder,
  từ chối server key và chặn chèn dòng vào xcconfig.
- Workflow mặc định yêu cầu `FIREBASE_IOS_CONFIG_JSON`, truyền vào Dart khi build.
  Chỉ `compile-only` cho phép xuất IPA chưa cấu hình tài khoản.
- Sửa Google Sign-In truyền `null` thay cho OAuth client ID trống.
  `flutter analyze --no-pub` không có vấn đề; 95 bài kiểm thử ứng dụng đạt.
- Chưa có Firebase project/provider nên chưa tạo IPA có tài khoản hoạt động,
  chưa kiểm thử OAuth thật. [Các bước Spark miễn phí](firebase-free-setup.md).
  Kết quả build bên dưới thuộc commit `833ff41`, trước thay đổi cấu hình này.

## iOS Release không ký trên GitHub Actions — 02/11/2026

- [Run 41443870844](https://github.com/AnhhPhuong06/HomNayAnGi/actions/runs/41443870844)
  build thành công mã ứng dụng tại commit `833ff41`, bằng Flutter 3.47.9/Xcode 26.3.
  Analyze và 95 bài kiểm thử đều đạt; 13 lượt xuất ảnh tùy chọn được bỏ qua trong CI.
- Đồng bộ FlutterFire về `firebase_core 4.15.2`, `firebase_auth 6.7.1`,
  `cloud_firestore 6.10.2`: Firebase iOS 12.19.3 đã vá bảo mật tương thích với
  GTMSessionFetcher 3.x của Google Sign-In 9.x. Firebase 13 hiện chưa tương thích.
- IPA 22.162.041 bytes, arm64, bundle `vn.homnayangi.homNayAnGi`, bản `1.0.0+1`,
  iOS 15.0+. Kiểm tra ZIP CRC, binary Mach-O, catalog/logo khớp mã nguồn và
  không có chữ ký ứng dụng/provisioning profile.
  SHA-256: `6f3b092889265f7d9ef25828271a5ace8965da6edae40437dc3df25d1d728f85`.
- Chưa chạy Simulator/iPhone thật, chưa xác minh OAuth iOS. IPA cần ký lại trước
  khi cài; Firebase và tài khoản Google/Facebook/Apple vẫn cần cấu hình riêng.
  Kết quả này thay thế giới hạn "chưa build native iOS" trong baseline bên dưới.

## UX/UI thích ứng, cá nhân hóa và địa điểm cộng đồng — 02/11/2026

- `flutter analyze --no-pub`: không có vấn đề; 95 unit/widget tests đạt.
  13 lượt xuất ảnh giao diện chạy riêng đạt; đã xem ảnh phone/tablet/màn hình lớn.
- Kiểm tra năm tab ở 320×568, 390×844, 844×390, 800×1280 và 1440×900;
  có chữ hệ thống phóng tới 2,6 lần ở 320×568. Kiểm tra đổi kích thước giữ tìm
  kiếm/tab, màu lưu theo tài khoản, chọn món giảm chuyển động và bộ chọn ghim
  ở màn hình nhỏ/chữ lớn. Không coi các bài này là thử trên mọi thiết bị thật.
- 11 Firestore Emulator rules tests đạt, gồm bài địa điểm mới: chia sẻ giữa UID
  kiểm thử, chặn giả UID/tọa độ lỗi/ID OSM và xóa bài đúng chủ.
- Bài địa điểm có ghim, tìm trong Cộng đồng, chỉ đường và báo cáo/chặn/xóa.
  Quyền riêng tư đã cập nhật. Chưa deploy Firebase/provider hay xác minh OAuth
  production. Không có phiên giả trong entry point shipping.
- [Cách dùng, ảnh và giới hạn](adaptive-community.md). Mục Cộng đồng hiện lấy
  địa điểm từ 30 bài mới nhất, chưa phải catalog địa điểm phân trang đầy đủ.
- Chưa đo FPS profile/release trên thiết bị thật, chưa build/sign native iOS.
- APK `lib/main.dart` build thành công; CRC/ảnh logo nguồn khớp và không có UID
  fixture native trong kernel đóng gói. [APK adaptive](../artifacts/hom_nay_an_gi-adaptive-debug.apk)
  có SHA-256 `41f9bdc836679da2ea1428498760f6dbf5278671925884e515817792871df179`.
  Đây là APK debug cài thử, chưa phải bản ký phát hành cửa hàng.
- Android API 36: integration test đạt với catalog thật và Auth/Blog fixture;
  lưu màu, điền/đăng địa điểm bằng ghim công khai và thấy bài trong Cộng đồng.
  Đã xem ảnh [cá nhân hóa](../artifacts/adaptive_personalization_native_fixture.png),
  [biểu mẫu](../artifacts/adaptive_place_form_native_fixture.png) và
  [địa điểm](../artifacts/adaptive_places_native_fixture.png).
- Cài/mở bản chính và xem [đăng nhập native](../artifacts/adaptive_login_native.png).
  Sau integration test đã cài lại APK chính; output mặc định cũng là bản chính.
  Test không xác minh OAuth hay ghi Firestore production. Nền tile vẫn lỗi kết
  nối ở môi trường emulator; đã xác nhận trường hợp lỗi nền và nhập tọa độ.

## Khẩu vị, bản đồ và sao lưu — 02/11/2026

- `flutter analyze --no-pub`: không có vấn đề. 78 unit/widget tests đạt;
  8 bài xuất ảnh tùy chọn chạy riêng đều đạt. Format 66 file không cần thay đổi.
- 10 Firestore Emulator rules tests đạt (7 bài cộng đồng và 3 bài mới về
  quyền sở hữu bản sao lưu, schema/giới hạn payload, revision và timestamp).
- Hồ sơ khẩu vị được áp dụng cho gợi ý, trang chủ và Khám phá; quán ẩn/món tránh
  không được đưa lại khi nới bộ lọc. Có thông báo khi mọi ứng viên đều mới chọn.
- Dữ liệu local tách theo tài khoản, nhập dữ liệu cũ theo xác nhận. Sao lưu thủ công
  không chứa GPS/khu vực/theme; thao tác trả về trễ không ghi sang tài khoản mới.
  Có kiểm thử riêng cho khôi phục, gợi ý và trình sửa khẩu vị khi đổi tài khoản.
- Map dùng tọa độ catalog OSM thật, tối đa 80 ghim, attribution thường trực;
  có chọn quán khi tắt nền mạng. Chưa coi cache tile là bản đồ offline đầy đủ.
- Integration test trên Android API 36 đạt với catalog thật và tài khoản fixture:
  lưu khẩu vị, mở bản đồ và màn sao lưu. Máy chủ tile trả lỗi kết nối trong lượt
  chạy; đã kiểm tra thông báo lỗi và ghim vẫn hiển thị, chưa xác nhận tải nền online.
  [Khẩu vị native](../artifacts/upgrade_taste_native_fixture.png),
  [bản đồ native](../artifacts/upgrade_map_native_fixture.png),
  [cài đặt native](../artifacts/upgrade_settings_native_fixture.png).
- [Cách dùng, ảnh và giới hạn](upgrades.md). Các ảnh `fixture` dùng phiên kiểm thử,
  không xác nhận OAuth/backend production. Firebase/provider vẫn cần cấu hình.
- Native iOS vẫn cần build/run/sign trên Mac.
- APK shipping `lib/main.dart` build thành công:
  [hom_nay_an_gi-upgraded-debug.apk](../artifacts/hom_nay_an_gi-upgraded-debug.apk),
  SHA-256 `fd4878dc0988428fb9196761f07bf255bb0316b4703a078ec15303c7e49e547e`.
  Đã xác minh ZIP CRC, ảnh logo không đổi và không đóng gói entry point của phiên
  kiểm thử native. APK debug dùng cài thử; chưa phải bản ký phát hành cửa hàng.
- Đã cài lại bản shipping, khởi động Android sạch và xác nhận app ở
  [màn đăng nhập](../artifacts/upgrade_login_native.png): đủ ba provider, dịch vụ
  chưa cấu hình được vô hiệu hóa, không truy cập các tab qua phiên fixture.

## Logo Facebook được chọn — 31/10/2026

- Dùng đúng ảnh PNG đỏ/cam từ page `100068950842301` do người dùng chỉ định,
  không thay chữ hoặc vẽ lại. [Nguồn, SHA-256 và giới hạn 447 px](branding.md).
- 63 unit/widget tests đạt; 5 lượt render giao diện sáng/tối, trang chủ, blog
  và khám phá đạt. Format 57 file không cần thay đổi.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter build apk --debug --no-pub`: Gradle assembleDebug thành công. Đã kiểm tra
  APK CRC, ảnh nguồn đóng gói khớp SHA-256 và không còn layer monochrome cũ.
  [APK logo Facebook](../artifacts/hom_nay_an_gi-facebook-logo-debug.apk),
  SHA-256 `8c69fd5b2afa321150ca8e2794f3cd6176665a02c3ded96c0a2537b4477a79f2`.
- Đã cài APK trên Android emulator API 36 và xem logo ở
  [launcher](../artifacts/facebook_logo_launcher_native.png),
  [khởi động](../artifacts/facebook_logo_splash_native.png) và
  [đăng nhập](../artifacts/facebook_logo_login_native.png).
- 19 AppIcon iOS đúng kích thước slot, RGB không alpha, PNG CRC hợp lệ;
  Android resource XML parse thành công. Các bản 512/1024 px là ảnh nội suy.
- Xóa tài nguyên vector và monochrome của logo xanh khỏi bản hiện tại;
  adaptive icon có nền trắng và khoảng trống giữ nguyên toàn bộ logo.
- Native iOS chưa build/sign trên Windows. Firebase/provider vẫn cần cấu hình
  trước khi đăng nhập thật; thay logo không mở quyền truy cập khi chưa có phiên.

## Logo bát ăn trước đó — 31/10/2026

- Biểu trưng bát ăn/làn hơi dấu hỏi dùng chung vector cho UI và bộ icon.
  [Bộ logo trước đó](../artifacts/logo-previous-green/README.md).
- `flutter analyze --no-pub`: không có vấn đề; 63 unit/widget tests đạt,
  5 bài xuất ảnh chạy riêng đều đạt. Format 57 file không có thay đổi cần áp dụng.
- Kiểm tra AppIcon iOS: đúng kích thước từng slot, PNG RGB không có alpha;
  SVG, Android resource XML và iOS launch storyboard parse thành công.
- `flutter build apk --debug --no-pub`: thành công. APK có tài nguyên adaptive,
  monochrome và logo Flutter mới; cài/mở trên Android emulator API 36.
  Đã xem [launcher](../artifacts/logo_launcher_native.png),
  [khởi động](../artifacts/logo_splash_native.png) và
  [đăng nhập](../artifacts/logo_login_native.png).
- File [hom_nay_an_gi-logo-debug.apk](../artifacts/hom_nay_an_gi-logo-debug.apk),
  SHA-256 `46015bdbb52a1aa09e66b03259ad40ce8c6b613e713d181c85666125d03dee5c`.
- Xcode ZIP cập nhật source/icon/ảnh kiểm chứng. Chưa build/sign native iOS
  trên Windows. Firebase/provider chưa cấu hình nên bản cài vẫn ở đăng nhập.

## Giao diện hiện đại — 31/10/2026

- `flutter analyze`: không có vấn đề; 63 unit/widget tests đạt. Hai kiểm tra mới
  bao phủ đăng nhập cỡ chữ lớn và blog ở màn hình ngang.
- 5 lượt render giao diện sáng/tối, trang chủ, blog trống và khám phá đạt; tiện ích
  render được bỏ qua trong suite mặc định và chạy riêng bằng flag.
- APK debug mới build thành công, có đủ bốn font Be Vietnam Pro, giấy phép font
  và catalog 18.668 địa điểm. File:
  [hom_nay_an_gi-modern-debug.apk](../artifacts/hom_nay_an_gi-modern-debug.apk).
  SHA-256 `6a93cf140a142896198dae018c2640fed68cb5c2736c49814315e15ac3c250d6`.
- [Chi tiết và ảnh giao diện](design.md). Ảnh trang chủ/blog/khám phá dùng phiên
  tài khoản kiểm thử và catalog thật, không phải bằng chứng OAuth production.
- Đã cài/mở APK modern trên Android API 36, xác nhận font và ảnh tải đúng, đủ ba
  nút đăng nhập và không mở tab chính khi chưa cấu hình.
  [Ảnh bản cài thực tế](../artifacts/modern_login_native.png).

## Cập nhật ảnh / tài khoản / blog — 31/10/2026

- `flutter analyze`: không có vấn đề; 61 unit/widget tests đạt.
- 7 Firestore Emulator rules tests đạt: chặn anonymous, chống giả UID, giới hạn
  schema/timestamp, chỉ chủ bài xóa, bảo vệ báo cáo và danh sách chặn.
- Có ảnh món minh họa offline; đăng nhập Google/Facebook/Apple bắt buộc; tab Blog
  hỗ trợ hai loại chia sẻ, xóa bài, báo cáo/chặn và xóa tài khoản.
- Test UI dùng repository giả trong thư mục test. Chưa xác minh OAuth thật hoặc
  deploy Firebase vì người dùng chưa có project/provider. Xem [community.md](community.md).
- Native iOS vẫn cần build/run/sign trên macOS; ZIP là source project Xcode.
- Đã cài APK app thường lên Android API 36, force-stop/mở lại và kiểm tra ảnh món
  cùng đủ ba nút đăng nhập. Chưa cấu hình backend thì app ở màn hình đăng nhập,
  không mở tab chính hoặc tự tạo phiên. [Ảnh kiểm chứng](../artifacts/community-login.png).
- Bản build cuối `flutter build apk --debug --no-pub` thành công. Đã kiểm tra trực
  tiếp quyền trong APK bằng `aapt2`: không có AD_ID hoặc AdServices permissions.
  APK có đủ 18.668 địa điểm và 8 ảnh món offline. File bàn giao:
  [hom_nay_an_gi-community-debug.apk](../artifacts/hom_nay_an_gi-community-debug.apk),
  SHA-256 `a447e1dfc2197b78173d24e42f223d8a067879c6d7bb59dd2670e060b63f8e23`.
- `community_flow_test.dart` đã được thêm để chạy tiếp trên thiết bị; chưa chạy
  bài integration này trong phiên xác minh. Kiểm tra native ở trên là kiểm tra
  thủ công trên app thường; 61 test đạt là unit/widget tests.

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

## Nâng cấp 1.1.0+2 — 05/11/2026

- Nhắc cập nhật khi mở/quay lại app; phiên bản thật từ gói cài, kiểm tra thủ công, cache 6 giờ, hoãn cùng bản 24 giờ, tắt nhắc theo thiết bị. Tách kênh IPA manual khỏi App Store/TestFlight; không tự cài mã, không dùng push.
- Thêm màn hình quản trị 100 báo cáo gần nhất, phân quyền server, xử lý giữ/gỡ bài; gỡ bài cần xác nhận thứ hai. Client không tự cấp quyền và admin không đọc được backup riêng của thành viên.
- Provider chưa cấu hình có thông báo rõ; Facebook/Apple mặc định chưa bật. Giữ Google client configuration trong secret hiện có.
- Kiểm tra cục bộ: `flutter analyze` không có lỗi; 118 Flutter tests đạt, các ca preview mặc định bỏ qua. 7 account configuration tests, 4 release preparation tests và 15 Firestore Emulator rules tests đạt. Preview hộp thoại tại `artifacts/update_dialog_fixture.png` dùng phiên bản giả lập 1.2.0 để minh họa, không phải release đã công bố.
- Chưa xác minh đăng nhập trên iPhone thật. Chưa triển khai Firestore production trong phiên này vì Firebase CLI đang chờ chủ project hoàn tất đăng nhập Google. Chưa cấp admin cho UID nào.
- Bản native 1.1.0+2 và public update feed được xác minh riêng sau khi GitHub build hoàn tất; kết quả build 1.0.0 ở các phần trước không phải bằng chứng cho 1.1.0.
