# Nhắc cập nhật từ 1.1.0

Ứng dụng kiểm tra khi mở và khi quay lại foreground. Hộp thoại hiển thị phiên bản/số build, nội dung thay đổi, **Cập nhật** và **Nhắc sau**. Nhắc sau hoặc đóng hộp thoại hoãn cùng bản đó 24 giờ trên thiết bị. Không gửi push khi app đã đóng. Không tự tải hoặc cài mã.

**Cài đặt → Giới thiệu & cập nhật** có phiên bản thật đọc từ gói cài, công tắc nhắc và nút kiểm tra thủ công. Kiểm tra thủ công bỏ qua cache và thời gian hoãn. Mất mạng không chặn dùng app và không hiển thị kết luận sai rằng đang ở bản mới nhất.

Kiểm tra tự động dùng cache tối đa 6 giờ và giới hạn thử lại trong một phiên ít nhất 15 phút. Có thể tắt hoàn toàn kiểm tra tự động; lựa chọn này áp dụng cho thiết bị. Yêu cầu HTTPS tới file JSON công khai trên GitHub không kèm UID, email, tọa độ hoặc token Firebase. GitHub vẫn nhận địa chỉ IP như một yêu cầu web thông thường.

## Kênh cài đặt

`config/app_updates.json` chứa schemaVersion 1 và tối đa 10 bản phát hành, mỗi bundle/kênh một bản. App so sánh số major, minor, patch và build; chỉ lấy đúng bundle và kênh.

- Workflow **Build unsigned IPA** truyền `--dart-define=APP_UPDATE_CHANNEL=iosManual`. Kênh này chỉ mở trang Releases của chính repository, IPA phải ký lại trước khi cài.
- Tự chuẩn bị Xcode để cài thủ công: `bash ios/open_xcode.sh --dart-define=APP_UPDATE_CHANNEL=iosManual --dart-define-from-file=config/firebase.ios.json`. Cờ này phải có khi tạo cấu hình build trên Mac; không sửa pubspec để giả phiên bản đang cài.
- Build iOS mặc định dùng App Store; không được dùng cờ `iosManual` cho bản nộp Store. Receipt TestFlight chọn kênh TestFlight. `package_info_plus` không phân biệt đáng tin cậy IPA chưa có receipt với App Store, nên kênh manual phải được chọn rõ lúc build.
- Chưa có bản App Store/TestFlight/Google Play được phát hành. Các kênh này chưa có entry; không chuyển người dùng Store sang IPA unsigned.
- Bản 1.0.0 chưa có bộ kiểm tra này. Cần cài 1.1.0 một lần để nhận nhắc cho những bản tiếp theo.

## Phát hành lần tiếp theo

1. Tăng `version` trong pubspec.yaml; viết `docs/releases/<version>.md` (tối đa 2.000 ký tự), commit và push main.
2. Chạy **Build unsigned IPA**, chọn `configured`, đợi thành công và kiểm tra artifact.
3. Chạy **Publish manual iOS update**, nhập ID của build vừa thành công. Workflow yêu cầu build thủ công thành công từ main; từ chối khi app, asset, native, backend hoặc đầu vào build đã thay đổi. Chỉ cho phép các thay đổi tài liệu/test/công cụ phát hành sau build. Nó kiểm tra bundle, phiên bản/build, nền tảng thiết bị, CRC, đường dẫn ZIP, tính unsigned và cấu hình Google/Firebase thực sự có trong IPA để loại compile-only. Không tìm cảnh báo bằng grep toàn bộ log vì GitHub cũng in cả nhánh lệnh chưa chạy.
4. Workflow tạo draft Release, tải IPA và SHA-256, công bố Release rồi mới commit metadata cập nhật. Không công bố feed trỏ tới bản chưa tải được. Nếu Release đã tồn tại, workflow dừng để người quản lý kiểm tra, tránh ghi đè âm thầm.
5. Kiểm tra trang Release và JSON công khai. Bản đang cài cùng phiên bản/build không được nhắc. Dùng một bản cũ có bộ kiểm tra để xác minh luồng trên iPhone.

Tag phát hành trỏ tới main lúc công bố; SHA nguồn thực sự được build được ghi riêng trong Release và EXPORT_MANIFEST. Các đầu vào app/native/assets/backend/build phải giữ nguyên giữa hai commit. Cách này cho phép cập nhật tài liệu/công cụ phát hành mà không làm sai nguồn gói cài và tránh yêu cầu quyền sửa workflow khi tạo tag cho một commit cũ ([quy tắc GitHub](https://docs.github.com/en/rest/releases/releases#create-a-release)).

Nếu policy GitHub chặn bot push main, Release vẫn tồn tại nhưng feed chưa đổi; kiểm tra asset trước rồi commit file metadata đã chuẩn bị. Không hạ phiên bản feed hoặc đưa draft/compile-only lên feed. Script `tool/prepare_app_release.py` chỉ chuẩn bị metadata, không tự công bố.

## Kiểm thử

`flutter test test/update_test.dart` kiểm tra so sánh phiên bản/build, URL hợp lệ, đúng kênh, hoãn 24 giờ, cache, mất mạng, tắt nhắc, kiểm tra đồng thời, response về khi app ở nền, khởi động và hộp thoại chữ lớn trên màn hình nhỏ. Đây là kiểm thử logic/widget; không thay thế xác minh trên iPhone thật.
