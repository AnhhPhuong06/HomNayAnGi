# Chỉ dùng ảnh thật tại quán — 1.1.1+3

Đã bỏ ảnh món ăn mẫu ở đăng nhập, banner Trang chủ, danh mục, thẻ quán, chi tiết quán, màn hình viết Blog và bài Blog. Màn hình đăng nhập/banner dùng màu thương hiệu; danh mục dùng biểu tượng giao diện. Logo người dùng đã chọn được giữ nguyên.

Thẻ quán có ảnh xác minh tiếp tục hiện ảnh, tác giả/giấy phép và liên kết nguồn. Thẻ chưa có ảnh hiển thị thông tin gọn, không dành một khung ảnh lớn. Ảnh thật bị lỗi hiển thị trạng thái chưa tải được. Trường imageUrl không có đối chiếu không được đưa vào giao diện. Blog chỉ hiện ảnh khi cả ID lẫn tên quán gắn kèm khớp catalog; bài không gắn quán và địa điểm mới do thành viên tự nhập giữ nội dung chữ.

Đã xóa 8 JPEG mẫu và bỏ `assets/images/` khỏi khai báo Flutter assets. Ảnh món ăn mẫu không có trong gói cài mới. Những ảnh chụp màn hình/bản IPA trước 1.1.1 trong lịch sử kiểm tra có thể vẫn chứa giao diện cũ.

Hiện có **10 ảnh cho 10 quán / 18.668 địa điểm**, có tác giả, giấy phép và đối chiếu chi nhánh. Bổ sung Làng cà phê Trung Nguyên ở Buôn Ma Thuột: ảnh toàn cảnh năm 2014, tác giả vi:User:Pttp1991, CC BY-SA 3.0; tên nguồn và tọa độ trong khuôn viên phù hợp với địa điểm OSM. Ảnh phản ánh thời điểm chụp. Xem `assets/venue_photos/CREDITS.md` và nguồn trong ứng dụng.

Đã rà các tham chiếu ảnh/wiki trực tiếp của catalog OSM và một số nguồn Commons. Không có ảnh hợp lệ cho toàn bộ danh mục. Danh sách quán được giữ đầy đủ; có thể dùng **Khám phá → Có ảnh tại quán** để xem các quán đã có ảnh. Nhập thêm ảnh sau khi đối chiếu bằng `tool/data/venue_photo_sources.json` và `tool/data/import_venue_photos.py`.

Kiểm thử bổ sung kiểm tra bundle không có ảnh mẫu, chặn URL ảnh chưa duyệt, ảnh thật lỗi không dùng ảnh mẫu, Blog không gắn quán không có ảnh và Blog gắn sai tên quán không nhận ảnh.
