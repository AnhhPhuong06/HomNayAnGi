# Hôm Nay Ăn Gì?

**1.1.0 (build 2):** Nhắc cập nhật khi mở hoặc quay lại app; xem [hướng dẫn](docs/app-updates.md). [Quản trị báo cáo cộng đồng](docs/moderation.md) cần triển khai Firestore và cấp quyền trên máy chủ.

**UX/UI thích ứng:** thanh bên trên cửa sổ rộng, thẻ nhiều cột, màu/cỡ chữ/thẻ gọn
và giảm chuyển động theo cá nhân. Có thêm địa điểm kèm ghim để thành viên khác
biết trong Blog và Khám phá → Cộng đồng. [Cách dùng và giới hạn](docs/adaptive-community.md).

**Bản nâng cấp 02/11:** hồ sơ khẩu vị, ẩn quán, giảm lặp gợi ý, bản đồ OSM trong
Khám phá và sao lưu/khôi phục thủ công theo tài khoản. [Cách dùng và giới hạn](docs/upgrades.md).

Ứng dụng Flutter giúp chọn món và tìm quán trong vài thao tác: **mở app → chọn giúp tôi → xem quán → chỉ đường**.

App dùng **danh mục quán thật từ OpenStreetMap Việt Nam**, trích từ snapshot Geofabrik và đóng gói để chạy ngoại tuyến. Danh mục không cần Places API key. Số lượng, thời điểm nguồn và phạm vi thực tế nằm trong `assets/data/catalog_manifest.json`.

**Bản mới yêu cầu đăng nhập Google/Facebook/Apple**, có ảnh món ăn minh họa offline và tab Blog để chia sẻ bữa ăn/quán ngon. Cần cấu hình Firebase Auth, Firestore và provider trước khi đăng nhập thật. Khi chưa cấu hình, app giữ người dùng ở màn hình đăng nhập. Hướng dẫn đầy đủ: [docs/community.md](docs/community.md).

**Giao diện mới:** xanh rừng/kem, font tiếng Việt offline, thẻ ảnh, danh mục món
cuộn ngang và thanh điều hướng nổi. [Xem giao diện và kiểm tra](docs/design.md).

**Logo hiện tại:** logo đỏ/cam từ trang Facebook do người dùng chọn, đồng bộ trong
app, Android/iOS và màn khởi động. [Nguồn ảnh và bộ PNG](docs/branding.md).

Dữ liệu cộng đồng có thể thiếu hoặc đã thay đổi, không phải danh sách mọi quán đang hoạt động tại Việt Nam. Không tự điền giá, sao đánh giá, review count hoặc ảnh khi nguồn không cung cấp. Google Maps được mở bằng tọa độ để chỉ đường; nút **Tìm video trên TikTok** là tìm kiếm theo tên quán và khu vực, không phải review đã xác minh. Không sao chép hàng loạt nội dung Google Maps/TikTok.

Bộ **24 quán demo** giữ riêng cho test, bật bằng `--dart-define=RESTAURANT_DATA=demo`, không trộn vào catalog thật. Quy trình nhập/cập nhật nguồn và liên kết đối chiếu: [docs/open-data.md](docs/open-data.md).

## Chức năng

- Năm tab: Trang chủ, Khám phá, Yêu thích, Blog, Cài đặt.
- Chọn khu vực từ nguồn dữ liệu; GPS chỉ được xin khi người dùng bấm nút. Có thể nhập tên và tọa độ tâm khu vực khác tại Việt Nam.
- Kiểu món theo dữ liệu; lọc ngân sách, khoảng cách, bữa ăn và người đi cùng. Bộ lọc chỉ lưu khi bấm Áp dụng.
- Recommendation chấm điểm khoảng cách, ngân sách, bữa ăn, đánh giá, sở thích và độ mới; lấy nhóm đầu rồi chọn ngẫu nhiên có trọng số.
- Nới khoảng cách tối đa 10 km, rồi ngân sách và kiểu món nếu cần; thông báo thay đổi. Không tự gợi ý quán cách hàng trăm km.
- Tránh lặp ngay quán/món vừa chọn khi có lựa chọn phù hợp khác. Lịch sử giữ tối đa 20 mục, mới nhất trước.
- Hiệu ứng chọn món 600 ms chạy đồng thời với tính toán; có tùy chọn giảm chuyển động và tôn trọng trợ năng hệ thống.
- Chi tiết quán, hình ảnh, giá, địa chỉ và dữ liệu tùy chọn; không suy diễn trạng thái “đang mở”. Mở chỉ đường bằng URL HTTPS Google Maps qua app hoặc trình duyệt.
- Tìm tên, món, danh mục, tag và từ khóa, hỗ trợ tìm không dấu. Dataset nhỏ được tìm local tức thời.
- Yêu thích, lịch sử, khẩu vị, theme và bộ lọc lưu local theo tài khoản khi bật backend. Có sao lưu/khôi phục thủ công dữ liệu cá nhân; GPS/khu vực/theme không lên bản sao lưu. Theme sáng/tối/theo hệ thống. GPS chính xác chỉ giữ trong phiên.
- Sau khi có phiên đăng nhập, catalog quán, yêu thích, ảnh món minh họa và cài đặt dùng được offline. Ảnh minh họa được ghi nhãn rõ. Đăng nhập lần đầu, blog chung, chỉ đường và tìm kiếm TikTok cần kết nối/dịch vụ ngoài.
- Loading, empty, error, retry; chống bấm lặp action async; thông báo nếu lưu local thất bại.

Không có delivery, thanh toán hoặc chat. Bản mới dùng Firebase Auth/Firestore cho tài khoản và blog; không bật Firebase Analytics.

## Stack và SDK

- Flutter Stable 3.47.9 / Dart 3.13.7 dùng phát triển bản này.
- Material 3, Riverpod 3, go_router 17, Dio 5, geolocator 14, url_launcher 6, shared_preferences 2.
- Phiên bản giải quyết thực tế được khóa trong `pubspec.lock`; commit lockfile cho ứng dụng.
- Không dùng code generation: model hiện nhỏ, dùng constructor và parser có validation.

## Chạy trên Windows / Android

1. Cài Git và [Flutter Stable](https://docs.flutter.dev/install), thêm `flutter/bin` vào PATH.
2. Cài Android Studio hoặc command-line tools theo [hướng dẫn Android](https://docs.flutter.dev/platform-integration/android/setup). Cần platform 36, build-tools, platform-tools, JDK 17+; Flutter tự tải NDK được pin nếu thiếu.
3. Tạo emulator hoặc kết nối Android thật, bật USB debugging.
4. Trong thư mục dự án:

```powershell
flutter pub get
flutter doctor -v
flutter doctor --android-licenses
flutter devices
flutter analyze
flutter test
flutter run -d <android-device-id>
```

Trên máy triển khai lần đầu, Flutter ở `D:\devtools\flutter`, Android SDK ở `D:\devtools\android`; JDK 21 đã có sẵn. User PATH và ANDROID_HOME đã được thiết lập; mở terminal mới để nhận PATH. Dùng ngay trong terminal cũ:

```powershell
$env:Path = 'D:\devtools\flutter\bin;D:\devtools\android\platform-tools;' + $env:Path
flutter config --android-sdk D:\devtools\android
```

Không cần Xcode/macOS để phát triển Android. Web scaffold dùng preview khi cần; Android và iOS là mục tiêu sản phẩm.

`android/gradle.properties` tắt Kotlin incremental compilation vì project và Pub cache nằm trên hai ổ Windows khác nhau; Kotlin không relativize được các đường dẫn đó. Đây không phải tắt lint/test. Khi chuyển project và Pub cache về cùng ổ có thể bỏ cấu hình này để tăng tốc build Kotlin.

## Kiểm thử và build

```powershell
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test/open_data_flow_test.dart -d <android-device-id> --no-uninstall
flutter test integration_test/core_flow_test.dart -d <android-device-id> --no-uninstall --dart-define=RESTAURANT_DATA=demo
flutter build apk --debug
```

APK cài thử: `build/app/outputs/flutter-apk/app-debug.apk`.

Bản nâng cấp mới nhất: [APK adaptive](artifacts/hom_nay_an_gi-adaptive-debug.apk)
và [project Xcode](artifacts/hom_nay_an_gi-xcode.zip). Cấu hình đăng nhập theo
[docs/community.md](docs/community.md).

Bản đã kiểm tra với 18.668 địa điểm OSM ngày 30/10/2026:
[APK dữ liệu thật](artifacts/hom_nay_an_gi-open-data-debug.apk).
Phạm vi, checksum và kết quả kiểm thử: [docs/open-data.md](docs/open-data.md).

Bản cập nhật tài khoản/blog: [APK community](artifacts/hom_nay_an_gi-community-debug.apk),
[project Xcode](artifacts/hom_nay_an_gi-xcode.zip). APK này yêu cầu đăng nhập;
chưa cấu hình Firebase/provider sẽ hiển thị thông báo dịch vụ chưa sẵn sàng.
Thiết lập dịch vụ theo [docs/community.md](docs/community.md).

Unit tests kiểm tra Haversine, ngân sách, bữa ăn, weighted random, nới lọc, thiếu dữ liệu, tọa độ sai, trùng ID, lịch sử, serialize/deserialize và hàng đợi ghi. Widget tests kiểm tra Home, staged filters, kết quả/chi tiết, favorites, tìm kiếm, empty/error, từ chối GPS, theme, cỡ chữ lớn và fixture offline. Integration test dùng plugin lưu trữ thật, khởi tạo lại app để kiểm tra restore.

Để kiểm tra offline thật, tắt Wi-Fi/dữ liệu trên emulator rồi chạy integration test. Bài test không gọi Internet. Để xác minh cold restart ở mức OS, force-stop rồi mở lại app, kiểm tra Yêu thích/theme/khu vực thủ công.

Test quyền native riêng chỉ chạy trên emulator test đã cài ứng dụng. Chuẩn bị quyền bị từ chối cố định rồi chạy (không làm trên thiết bị người dùng):

```powershell
adb shell pm revoke vn.homnayangi.hom_nay_an_gi android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke vn.homnayangi.hom_nay_an_gi android.permission.ACCESS_COARSE_LOCATION
adb shell pm set-permission-flags vn.homnayangi.hom_nay_an_gi android.permission.ACCESS_FINE_LOCATION user-set user-fixed
adb shell pm set-permission-flags vn.homnayangi.hom_nay_an_gi android.permission.ACCESS_COARSE_LOCATION user-set user-fixed
flutter test integration_test/location_denied_test.dart -d <android-device-id> --no-uninstall --dart-define=RESTAURANT_DATA=demo
```

Khôi phục bằng `adb shell pm clear-permission-flags` với cùng package, permission và hai cờ `user-set user-fixed` cho cả hai quyền. Không dùng `flutter test integration_test/` trước khi chuẩn bị trạng thái cho test native này.

Để chạy `integration_test/location_gps_test.dart`, khôi phục các cờ trên, cấp cả hai quyền bằng `adb shell pm grant`, bật vị trí trên emulator và cung cấp tọa độ thử bằng `adb emu geo fix 106.072 21.183`. Bài test chỉ yêu cầu foreground GPS; không có quyền background.

### Release Android

Không ký release bằng debug key. Khi chưa có `android/key.properties`, Gradle tạo output **unsigned**; bản đó không phải bản phát hành cửa hàng. Để ký, sao chép `android/key.properties.example` thành `android/key.properties`, điền keystore riêng trên máy:

```powershell
flutter build apk --release
flutter build appbundle --release
```

Keystore, mật khẩu và `key.properties` bị loại khỏi Git. Giữ bản sao upload key an toàn ngoài repository.

### iOS

Archive/signing và kiểm thử native iOS cần **macOS + Xcode**, Apple signing team và thiết bị/simulator iOS. Windows không thể xác minh build iOS.

Gói chuyển sang Mac: [hom_nay_an_gi-xcode.zip](artifacts/hom_nay_an_gi-xcode.zip).
Giữ cả thư mục khi giải nén, chạy `bash ios/open_xcode.sh` để chuẩn bị và mở
`ios/Runner.xcworkspace`. Hướng dẫn chi tiết: [docs/xcode.md](docs/xcode.md).

```bash
bash ios/build_ios.sh
```

Script đặt `BYPASS_PERMISSION_LOCATION_ALWAYS=1` cho geolocator Apple qua Swift Package Manager, chỉ giữ quyền When In Use. `Info.plist` có giải thích tiếng Việt; không khai báo Always Location/background location. Khi build từ Xcode, đặt cùng biến trong môi trường resolve/build SPM. Nếu chuyển sang CocoaPods, đặt `BYPASS_PERMISSION_LOCATION_ALWAYS=1` trong preprocessor definitions của target `geolocator_apple` theo tài liệu package.

## Kiến trúc

Feature-first, chỉ thêm abstraction ở ranh giới thay dữ liệu. `RestaurantRepository` có interface vì demo và remote có vòng đời khác nhau. Widget gọi provider/service; thuật toán gợi ý, truy vấn, GPS, persistence và URL được tách khỏi UI.

```text
lib/
  main.dart                  # bootstrap storage và ProviderScope
  app.dart                   # MaterialApp, localization, theme
  core/
    providers.dart           # wiring và settings/recommendation controller
    network/api_client.dart  # Dio timeouts, error mapping, chưa gọi ở demo
    router/                  # go_router, shell 4 tab
    services/                # GPS, local storage, maps
    theme/ utils/ widgets/
  features/
    home/                    # hero, category, filter/location sheets
    discover/                # local search
    recommendation/          # preferences, config, scoring, result
    restaurants/             # model, repository, queries, card/detail
    favorites/
    settings/
assets/data/real_restaurants.json # catalog thật OpenStreetMap Việt Nam
assets/data/catalog_manifest.json # nguồn, snapshot, checksum, số lượng
assets/data/source_links.json # liên kết trực tiếp đã đối chiếu, nếu có
assets/data/restaurants.json # 24 bản ghi demo riêng cho test
assets/images/               # ảnh offline và nguồn ảnh
test/                        # unit/widget tests
integration_test/            # flow trên thiết bị/emulator
tool/generate_demo.py         # tái tạo fixture demo
tool/data/                   # nhập catalog thật, test geometry/provenance
```

### Dữ liệu toàn Việt Nam

Model lưu country (`VN`), province, area, tọa độ và provenance. Picker suy ra tỉnh/khu vực từ repository, không có nhánh business logic cho địa phương cụ thể. Catalog thật ghép khu vực từ polygon OSM; nhãn nguồn **không thay thế danh bạ hành chính chính thức**. Khu vực nhiều kết quả có tìm kiếm và giới hạn số hàng hiển thị. Khoảng cách thủ công tính từ tâm các địa điểm trong khu vực; GPS dùng tọa độ thực tế của phiên. Chế độ dữ liệu thật yêu cầu chọn khu vực/GPS trước khi gợi ý quán, tránh tự chọn một thành phố xa khi chưa biết vị trí.

### Tích hợp nguồn production

1. Implement `RestaurantRepository.load()` và `isDemo == false`, thay `repositoryProvider`. UI giữ nguyên hợp đồng.
2. Dùng `createApiClient(Uri)` với endpoint HTTPS được kiểm soát. Validate JSON bằng `Restaurant.fromJson`; chỉ hiển thị dữ liệu có nguồn và được phép sử dụng.
   Trường `dishName` tùy chọn cung cấp tên món cụ thể cho kết quả; nếu thiếu, dùng tên danh mục. Không suy diễn tên món từ thứ tự tags.
3. Với search từ server: debounce 300–500 ms, dùng `CancelToken` hủy request cũ khi query đổi, `ref.onDispose` hủy khi rời màn. Demo không có request theo ký tự.
4. Nếu cần, thêm cache response hợp lệ gần nhất tại repository. MVP chưa có remote cache/DB.
5. Tuân thủ điều khoản attribution/thời hạn cache của provider thực tế. Không trộn sponsored result vào điểm tự nhiên.

Không có remote repository giả lập hay backend chưa dùng. Dio helper hiện không phát request; không có logging interceptor dư thừa và không log header/token/tọa độ. Timeout/HTTP error có thông điệp thân thiện để remote repository dùng sau.

### Environment và secrets

Demo không cần cấu hình. `.env.example` là template hướng dẫn, app **không đọc .env**. Khi thêm remote, truyền endpoint public bằng `--dart-define=API_BASE_URL=...` và đọc tại lớp config/remote mới; bản hiện tại chưa dùng biến này.

`dart-define` không bảo vệ secret trong binary. Key đặc quyền phải nằm trên backend; key public mobile cần giới hạn app/package/signature theo provider. Không lưu secret trong SharedPreferences.

### Persistence / privacy

Một JSON versioned lưu preferences, favorites, theme và tối đa 20 history ID. Ghi nối tiếp để thao tác nhanh không ghi đè bản mới bằng bản cũ. Khi lỗi ghi, state phiên vẫn dùng được và banner cho phép lưu lại. Dữ liệu lỗi có thông báo và cài đặt mặc định để tiếp tục.

GPS không persist; khu vực thủ công persist. Android backup bị tắt. Không account/secret. Maps chỉ mở URL HTTPS dựng từ tọa độ đã kiểm tra, không mở `mapUrl` tùy ý từ JSON. Chính sách quyền riêng tư nằm trong Cài đặt; trước phát hành cửa hàng cần công bố URL chính sách của đơn vị vận hành và hoàn tất khai báo cửa hàng cho dữ liệu/provider thực tế.

Android dùng `LocationManager` cho một fix GPS có timeout, không yêu cầu bật Google Location Accuracy/Wi-Fi scanning. Không stream vị trí, không background/foreground notification service. Trong nhà hoặc khi không có tín hiệu vệ tinh, app timeout và cho chọn khu vực thủ công.

## Phạm vi xác minh

Kết quả và hạn chế môi trường ghi tại [docs/verification.md](docs/verification.md). Không coi dữ liệu demo là quán thật; không coi build Android là bằng chứng build iOS đã pass.
