# Build IPA unsigned bằng GitHub Actions

1. Mở [Build unsigned IPA](https://github.com/AnhhPhuong06/HomNayAnGi/actions/workflows/ios-unsigned.yml).
2. Chọn **Run workflow**, branch **main**, rồi **Run workflow**.
3. Mở lượt chạy vừa tạo. Khi thành công, tải artifact
   **hom_nay_an_gi-unsigned** ở cuối trang và giải nén để lấy
   **hom_nay_an_gi-unsigned.ipa**.

Workflow chạy trên macOS, dùng Flutter **3.47.9** và Xcode của runner.
Dependency được khóa bằng `pubspec.lock`. Analyze và unit/widget tests phải đạt
trước khi build Release với `--no-codesign` và đóng gói `Payload/Runner.app`.
Không cần Apple certificate, provisioning profile hoặc repository secret.
Artifact được giữ 14 ngày; tải về máy trước khi hết hạn.

IPA chưa ký, cần ký lại trước khi cài trên iPhone. Build không tự phát hành
lên TestFlight hay App Store và chỉ chạy khi được kích hoạt thủ công.
