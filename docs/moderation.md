# Quản trị báo cáo cộng đồng

**Đã triển khai 05/11/2026:** project `homnayangi-cba95`, database `(default)` Standard/Native tại Singapore, `freeTier: true`, billing tắt. Rules đã deploy và đọc lại khớp source. Tài khoản Google xác minh của project owner đã được cấp role admin bằng IAM sau khi đối chiếu cả quyền owner và tài khoản Firebase Auth. Không có UID/email quản trị hardcode trong app. Chưa kiểm tra đăng bài bằng hai client thật trên iPhone.

Màn hình **Cài đặt → Quản trị cộng đồng** chỉ xuất hiện sau khi Firestore xác nhận tài khoản có quyền quản trị. Hiển thị 100 báo cáo gần nhất, lọc chưa xử lý, xem bài bị báo cáo, giữ bài và hoàn tất báo cáo hoặc gỡ bài sau xác nhận thứ hai. Bài gỡ bị xóa khỏi Firestore và không thể hoàn tác.

Quyền được lưu trong document `roles/<Firebase Auth UID>` với trường boolean `admin: true`. Chỉ chủ project dùng Firebase Console hoặc công cụ server có IAM phù hợp được cấp/thu hồi quyền. Lấy UID của đúng tài khoản tại **Firebase Authentication → Users**, kiểm tra người sở hữu trước khi cấp. Không dùng email hardcode, không cấp từ app và không chia sẻ service-account key. Xóa role hoặc đổi admin thành false để thu hồi.

Rules chỉ cho người dùng đọc document quyền của chính họ; không cho client tạo/sửa/xóa/list roles, kể cả client đang là admin. Quyền quản trị không cho đọc backup riêng của người khác. Một báo cáo đã hoàn tất không được viết lại nội dung gốc hoặc mở lại qua client. Báo cáo cũ chưa có trường status được xem là chưa xử lý.

Triển khai vào đúng project miễn phí sau khi chủ project đăng nhập CLI:

```powershell
$env:DEBUG=''
node tool/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js login
node tool/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js firestore:databases:list --project homnayangi-cba95
# Khi đã có Firestore Native database (default), kiểm tra rules hiện hành trước:
node tool/firebase-tests/node_modules/firebase-tools/lib/bin/firebase.js deploy --only firestore:rules --project homnayangi-cba95
```

Nếu chưa có database, tạo Firestore Standard/Native bằng gói Spark trong Firebase Console, chọn vị trí phù hợp trước khi tạo. Không bật billing để thực hiện bản nâng cấp này. Không ghi đè rules đã tùy chỉnh ở production khi chưa đối chiếu.

Các kiểm thử emulator dùng project demo riêng, không thay đổi production. Chạy `npm test` trong `tool/firebase-tests` bên trong Firestore Emulator; có 15 ca bao gồm phân quyền, bài viết, báo cáo, backup riêng và thu hồi admin. Cần kiểm tra thêm trên backend thật với tài khoản thường và quản trị sau triển khai. Đây là xử lý báo cáo sau đăng; chưa phải hàng chờ duyệt địa điểm trước khi xuất bản.
