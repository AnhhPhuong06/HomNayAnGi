# Đăng nhập xã hội và blog ăn ngon

Nếu IPA báo dịch vụ tài khoản chưa sẵn sàng và bạn chưa có project,
làm theo [tạo Firebase Spark và build iOS có Google đăng nhập](firebase-free-setup.md).

Bản 02/11 thêm bài **Địa điểm mới** có ghim quán và mục Cộng đồng trong Khám phá.
Cần deploy rules mới. [Cách dùng và quyền riêng tư](adaptive-community.md).

App yêu cầu đăng nhập Google, Facebook hoặc Apple trước khi mở các màn hình chính.
Phiên được Firebase Authentication quản lý; ứng dụng không nhận mật khẩu tài khoản
nhà cung cấp. Chưa có project/cấu hình thì màn hình đăng nhập báo dịch vụ chưa sẵn
sàng, các nút chưa hoạt động và không có chế độ tự tạo phiên giả.

## Những gì đã có trong mã

- Ảnh món ăn đóng gói offline theo kiểu món. Khi không có ảnh đúng quán, ảnh được
  ghi rõ **Ảnh món ăn minh họa**, không biến ảnh stock thành ảnh quán đã xác minh.
- Tab **Blog**: xem 30 bài mới nhất, lọc Hôm nay ăn gì / Quán ăn ngon / Bài của tôi.
- Viết bài từ blog, kết quả chọn món hoặc trang chi tiết quán; đính kèm tên quán,
  khu vực và ID quán khi xuất phát từ catalog. Tên tác giả lấy từ phiên đăng nhập.
- Xóa bài của mình, báo cáo nội dung, chặn tác giả, bỏ chặn và xóa tài khoản/bài.
- Nội dung chia sẻ là trải nghiệm của thành viên, không tự biến thành giá/rating
  chính thức của địa điểm OSM. Không tự đăng bài khi chỉ bấm nút chọn món.

Blog chung dùng Firebase Auth và Cloud Firestore. Dùng **Spark** để bắt đầu trong
hạn mức miễn phí, không bật billing/Blaze trong quy trình này. Ảnh minh họa đi kèm
app; hiện chưa có tải ảnh cá nhân lên Cloud Storage hay tự đăng lên Facebook.
Apple Developer/signing có điều kiện tài khoản riêng của Apple; không coi đó là
một dịch vụ miễn phí do ứng dụng cung cấp.

## 1. Tạo Firebase project

1. Trong Firebase Console tạo project, giữ gói Spark; không cần bật Analytics.
2. Đăng ký Android app với package `vn.homnayangi.hom_nay_an_gi` và iOS app với
   bundle ID `vn.homnayangi.homNayAnGi` (hoặc đồng bộ toàn bộ cấu hình nếu đổi ID).
3. Bật **Authentication → Sign-in method**: Google, Facebook, Apple. Không bật
   Anonymous để thay cho yêu cầu đăng nhập. Các provider cần cấu hình tiếp bên dưới.
4. Tạo **Cloud Firestore Standard / Native mode**. Không dùng test rules mở toàn
   bộ dữ liệu. Deploy `firestore.rules` bằng Firebase CLI từ thư mục project:

   ```bash
   firebase login
   firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```

   Đọc cấu hình/quyền trước khi deploy. Mã chưa tự deploy vào tài khoản nào.
5. Copy `config/firebase.example.json` thành file riêng cho nền tảng, ví dụ
   `config/firebase.android.json` và `config/firebase.ios.json`. Điền API key,
   project ID, sender ID, app ID và OAuth client ID lấy từ Console. Firebase app
   ID Android/iOS khác nhau. API key trong mỗi file phải đúng nền tảng tương ứng.
   Các giá trị cấu hình client này không phải Admin SDK credential; quyền dữ liệu
   nằm ở Auth và Firestore rules. Không đưa service account key vào ứng dụng.

Chạy Android:

```bash
flutter run --dart-define-from-file=config/firebase.android.json
```

## 2. Google

1. Bật Google trong Firebase Auth và cấu hình support email/OAuth consent.
2. Thêm SHA-1/SHA-256 của debug/release signing certificate Android vào Firebase.
   Có thể xem bằng `android/gradlew signingReport`. Khi phát hành Google Play,
   thêm certificate của Play App Signing.
3. Điền **Web OAuth client ID** (không phải Android client ID) vào
   `GOOGLE_WEB_CLIENT_ID`. Plugin được khởi tạo bằng `serverClientId` trong Dart.
4. Với iOS, điền `GOOGLE_IOS_CLIENT_ID` từ `CLIENT_ID` của cấu hình iOS. Copy
   `ios/Flutter/Social.xcconfig.example` thành `Social.xcconfig`, đặt
   `GOOGLE_REVERSED_CLIENT_ID` bằng `REVERSED_CLIENT_ID` tương ứng. URL callback
   đã được nối trong `Info.plist`.

## 3. Facebook / Meta

1. Tạo Meta Developer app có Facebook Login. Thêm app ID/App Secret trong provider
   Facebook của **Firebase Console**. App Secret chỉ nằm ở console, không ở Dart,
   JSON client, repository hay APK/ZIP.
2. Đăng ký OAuth redirect URI Firebase cung cấp trong Meta Console; cấu hình
   privacy policy, data deletion URL và chế độ Live/permissions theo yêu cầu Meta.
   Trong development mode chỉ tài khoản có role/test account được phép thử.
3. Android: copy `android/social.properties.example` thành `android/social.properties`,
   điền Meta App ID và **Client Token** (khác App Secret). Thêm package, activity
   `vn.homnayangi.hom_nay_an_gi.MainActivity` và key hashes debug/release vào Meta.
4. iOS: trong `ios/Flutter/Social.xcconfig`, điền `FACEBOOK_APP_ID` và
   `FACEBOOK_CLIENT_TOKEN`; đăng ký đúng bundle ID ở Meta. Scheme `fb<appID>`
   được tạo qua `Info.plist`.

iOS dùng Facebook Limited Login với nonce ngẫu nhiên, SHA-256 và Firebase OIDC
credential; không xin quyền tracking để đăng nhập. Android hỗ trợ classic token.
Đã tắt tự ghi app events, thu advertising ID và Android AD_ID permission.

## 4. Apple

1. Đăng ký/cho phép **Sign in with Apple** cho App ID của bạn trong Apple Developer.
   Target Runner đã có entitlement; chọn Team và provisioning profile phù hợp.
2. Bật provider Apple trong Firebase Auth. Cấu hình Team ID, Key ID, private key
   và Service ID/redirect URI theo hướng dẫn Firebase, đặc biệt khi dùng Android
   hoặc web. Khóa `.p8` chỉ nhập ở Firebase Console, không đóng gói vào ứng dụng.
3. Trên iOS, mở project qua:

   ```bash
   bash ios/open_xcode.sh --dart-define-from-file=config/firebase.ios.json
   ```

   Run scheme Runner trên Mac. Archive bằng:

   ```bash
   bash ios/build_ios.sh --release --dart-define-from-file=config/firebase.ios.json
   ```

Lần đầu đăng nhập nhà cung cấp tạo Firebase user; những lần sau dùng lại user đó.
Nếu email đã thuộc một provider khác, app báo dùng lại cách đăng nhập trước đó;
không tự ghép tài khoản chỉ dựa vào email.

## Quyền dữ liệu và quản trị

`posts` chỉ đọc khi đã đăng nhập. Bài mới phải có authorId bằng UID trong token,
đúng trường/độ dài/kiểu món và timestamp máy chủ; không cho sửa bài sau đăng.
Chỉ chủ bài được xóa. `reports` riêng cho người gửi; quản trị viên xem/xử lý qua
Firebase Console/IAM, xóa nội dung vi phạm hoặc vô hiệu hóa tài khoản khi cần.
Danh sách chặn nằm dưới `members/{uid}/blocked`, chỉ UID đó truy cập từ client.

Trước khi mở cộng đồng công khai, đặt đầu mối hỗ trợ/privacy/data-deletion thực
tế trong các console và phân công người xem báo cáo; app không có hệ thống tự
kiểm duyệt hay giới hạn tần suất toàn server. App Check có thể bổ sung khi bật
production, không thay thế Firestore rules. Chưa triển khai backend nào trong
phiên làm việc này vì chưa có tài khoản dịch vụ.

Xóa tài khoản yêu cầu xác thực lại provider; bài, báo cáo và blocks của UID được
xóa trước khi xóa Firebase user. Apple iOS thu hồi authorization code qua Firebase.
Nếu mạng lỗi giữa chừng, app báo lỗi; chạy lại thao tác để hoàn tất phần còn lại.
Yêu thích/khu vực/theme và khẩu vị trên máy đã được tách theo Firebase UID.
Trong Cài đặt có sao lưu/khôi phục thủ công yêu thích, lịch sử, bộ lọc và khẩu vị
qua `profiles/{uid}`. Không sao lưu khu vực, GPS hay theme. Cần deploy rules mới;
xem [upgrades.md](upgrades.md). Dữ liệu chưa phân tài khoản từ phiên bản cũ chỉ
được nhập khi người dùng chủ động xác nhận.

Blog dùng cache Firestore khi SDK có dữ liệu cũ. Bài đang chờ máy chủ được ghi rõ;
không báo đã đăng thành công chỉ vì có bản local. Sau 20 giây chưa xác nhận, editor
yêu cầu kiểm tra blog trước khi viết lại. Lần đăng nhập đầu và OAuth cần Internet.

## Kiểm thử

```bash
flutter analyze
flutter test --concurrency=1
flutter test integration_test/community_flow_test.dart -d emulator-5554 --no-uninstall
cd tool/firebase-tests
npm ci
npx firebase emulators:exec --project demo-meal-community --only firestore "npm test"
```

Widget tests dùng repository giả chỉ trong thư mục test để kiểm tra điều hướng,
ba nút OAuth, hủy đăng nhập, viết/xóa/báo cáo/chặn bài. Rules tests dùng Firestore
Emulator, không chạm project thật. Bài integration catalog cũ override đăng nhập
ở test harness; chúng không phải bằng chứng OAuth thật đã pass.

Chưa kiểm tra Google/Facebook/Apple end-to-end với tài khoản thật vì chưa được
cấu hình provider. Windows không biên dịch/chạy native iOS; cần xác minh trên Mac.

## Tài liệu chính thức

- [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup)
- [Federated identity](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
- [Google Sign In](https://pub.dev/packages/google_sign_in)
- [Facebook plugin setup](https://facebook.meedu.app/docs/7.x.x/intro/)
- [Firebase Facebook Limited Login](https://firebase.google.com/docs/auth/ios/facebook-login)
- [Rules unit testing](https://firebase.google.com/docs/rules/unit-tests)
