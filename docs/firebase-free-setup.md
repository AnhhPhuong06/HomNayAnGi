# Bật đăng nhập Google miễn phí cho bản iOS

Thông báo “Dịch vụ tài khoản chưa sẵn sàng” trong IPA cũ xuất hiện vì chưa có
Firebase project/cấu hình. Chỉ đổi thông báo hoặc build lại cùng nguồn chưa cấu
hình sẽ không bật được tài khoản. Các bước sau tạo project của chính bạn và
đưa cấu hình vào bản IPA mới; không dùng tài khoản giả hay bỏ yêu cầu đăng nhập.

## 1. Tạo project Spark

1. Mở [Firebase Console](https://console.firebase.google.com/) và đăng nhập Google.
2. Chọn tạo project, đặt tên **Hom Nay An Gi**; project ID phải duy nhất nên có thể
   thêm hậu tố nếu đã có người dùng tên đó.
3. Tắt Google Analytics nếu không cần. Giữ **Spark**, không liên kết billing,
   không nâng lên Blaze. Spark không cần thông tin thanh toán; các sản phẩm có
   hạn mức sử dụng. [Thông tin gói chính thức](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).

## 2. Đăng ký đúng ứng dụng iOS và bật Google

1. **Project settings → Your apps → Add app → iOS**.
2. Bundle ID nhập chính xác `vn.homnayangi.homNayAnGi` (phân biệt hoa/thường).
   App nickname có thể đặt `Hom Nay An Gi iOS`; App Store ID có thể bỏ trống.
3. **Build → Authentication → Get started → Sign-in method → Google**:
   bật Google, chọn email hỗ trợ của bạn rồi lưu.
4. Quay lại cài đặt app iOS, tải mới **GoogleService-Info.plist** sau khi đã bật
   Google. File phải có `CLIENT_ID`; nếu thiếu hãy kiểm tra bước bật Google và
   tải lại. [Hướng dẫn Google Sign-In](https://firebase.google.com/docs/auth/ios/google-signin).

Không cần tạo Firestore để thử riêng đăng nhập Google. Để dùng blog/sao lưu,
tạo Cloud Firestore Standard ở production mode và triển khai `firestore.rules`
theo [community.md](community.md); không mở quyền đọc/ghi công khai.

## 3. Tạo cấu hình trên máy Windows

Tại Terminal PowerShell trong `D:\AppStore`, dùng đúng đường dẫn file đã tải:

```powershell
python tool/configure_ios_accounts.py --plist "$env:USERPROFILE\Downloads\GoogleService-Info.plist"
```

Script kiểm tra bundle ID, các ID cùng project và sinh:

- `config/firebase.ios.json`: cấu hình Firebase/Google truyền vào Dart.
- `ios/Flutter/Social.xcconfig`: URL callback Google khớp client ID.

Script không gửi file lên Internet và không in giá trị cấu hình. Không commit hai
file này, không gửi khóa/mật khẩu trong chat. Không cần copy plist vào Xcode vì
ứng dụng khởi tạo Firebase bằng các giá trị trong JSON.

## 4. Thêm cấu hình vào GitHub rồi build lại

1. Mở [repository secrets](https://github.com/AnhhPhuong06/HomNayAnGi/settings/secrets/actions).
2. **New repository secret**: tên `FIREBASE_IOS_CONFIG_JSON`; Value là toàn bộ
   nội dung file `D:\AppStore\config\firebase.ios.json` vừa tạo. Lưu secret.
3. Vào **Actions → Build unsigned IPA → Run workflow**, chọn `main` và
   `account_configuration = configured`.
4. Build thành công: tải artifact `hom_nay_an_gi-unsigned`, ký IPA rồi cài lại.
   Bản IPA cũ không tự nhận cấu hình mới từ GitHub.
5. Đăng nhập Google và kiểm tra người dùng mới ở **Firebase Authentication → Users**.
   Đây mới là xác minh đăng nhập thật, khác với build thành công.

Chế độ `compile-only` chỉ kiểm tra biên dịch; nó tạo IPA chưa có dịch vụ tài khoản.
Mặc định `configured` dừng sớm nếu thiếu/sai định dạng cấu hình. Kiểm tra cục bộ
không xác minh provider đã được bật hay API key được phép gọi backend.

## Facebook và Apple

Google đủ để dùng luồng đăng nhập bắt buộc trước. Facebook và Apple vẫn cần bật
provider và cấu hình tài khoản tương ứng theo [community.md](community.md).
Với Facebook, có thể thêm `FACEBOOK_APP_ID` và `FACEBOOK_CLIENT_TOKEN` vào JSON
trong GitHub Secret; script chỉ đưa chúng vào cấu hình native. **Không** thêm Meta
App Secret, Apple `.p8`, mật khẩu hoặc service-account key vào JSON này.
Apple cần entitlement/signing và cấu hình Apple Developer phù hợp; tài khoản
Firebase miễn phí không thay thế các yêu cầu của Apple.

Từ bản 1.1.0, script tự bật `FACEBOOK_LOGIN_ENABLED` chỉ khi cả App ID và client token đã hợp lệ. Apple mặc định tắt; chỉ thêm `"APPLE_LOGIN_ENABLED": true` vào cấu hình build sau khi đã hoàn tất provider, entitlement và signing. Không bật cờ chỉ để làm nút hết báo chưa cấu hình. Google vẫn dùng cấu hình hiện có.

Triển khai Firestore và cấp quyền xử lý báo cáo xem [moderation.md](moderation.md). Nhắc cập nhật không cần Firebase/push; xem [app-updates.md](app-updates.md).
