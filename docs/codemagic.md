# Build IPA unsigned trên Codemagic

Bản đồng bộ 02/11/2026 lấy từ thư mục Xcode người dùng chỉ định, gồm đăng nhập,
blog, UX/UI thích ứng, cá nhân hóa và địa điểm cộng đồng. Không tải khóa ký hay
cấu hình Firebase riêng lên GitHub. Khi chưa cấu hình Firebase/provider, bản
cài tiếp tục ở màn đăng nhập. Xem [community.md](community.md).

Workflow `ios-unsigned` trong [codemagic.yaml](../codemagic.yaml) dùng máy macOS,
Flutter **3.47.9**, Xcode và Swift Package Manager. Không cần certificate,
provisioning profile hay App Store Connect API key để build unsigned.

1. Đăng nhập [Codemagic](https://codemagic.io/apps), chọn **Add application** và
   kết nối repository `https://github.com/AnhhPhuong06/HomNayAnGi`.
2. Dùng cấu hình **codemagic.yaml** tại gốc repository.
3. Chọn **Start new build**, branch **main**, workflow
   **iOS Release - Unsigned IPA** (`ios-unsigned`), rồi bắt đầu build.
4. Khi build thành công, tải **hom_nay_an_gi-unsigned.ipa** trong **Artifacts**.

Workflow lấy dependency theo `pubspec.lock`, chạy analyze và unit/widget tests,
sau đó build `flutter build ios --release --no-codesign --no-pub`.
Script `ios/package_unsigned_ipa.sh` đóng gói `Payload/Runner.app` thành IPA,
giữ quyền thực thi và symlink, kiểm tra ZIP trước khi lưu artifact tại
`build/ios/ipa/hom_nay_an_gi-unsigned.ipa`.

Biến `BYPASS_PERMISSION_LOCATION_ALWAYS=1` được đặt cho toàn workflow theo cấu
hình geolocator của dự án. Không chạy CocoaPods vì workspace dùng SPM.
Workflow chạy thủ công; không tự build mỗi lần push và không phát hành lên store.

Trước khi chạy, kiểm tra commit của nhánh `main` là bản đồng bộ mới nhất.
Một build đã bắt đầu trước khi push vẫn dùng commit cũ; cần bắt đầu lượt mới
để tạo IPA của mã mới. Không dùng IPA của lượt cũ làm bằng chứng cho bản mới.

IPA này **chưa ký**, cần ký lại bằng công cụ/tài khoản phù hợp trước khi cài
lên iPhone. Không dùng trực tiếp cho TestFlight hoặc App Store.

Có thể chạy cùng quy trình trên Mac:

```bash
export BYPASS_PERMISSION_LOCATION_ALWAYS=1
flutter config --enable-swift-package-manager
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign --no-pub
bash ios/package_unsigned_ipa.sh
```

Cấu hình dựa trên tài liệu chính thức:
[Using codemagic.yaml](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
và [Flutter apps](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/).
