# Dữ liệu thật không dùng dịch vụ trả phí

Nguồn mặc định là OpenStreetMap Việt Nam, trích từ Geofabrik. Google Maps được
dùng để mở chỉ đường bằng tọa độ; TikTok được mở để tìm video theo quán/khu vực.
Phần danh mục không dùng Google Places API key, billing, backend hoặc request
Places. Tài khoản và blog của bản cập nhật dùng Firebase riêng; xem
[community.md](community.md).

## Phạm vi

`assets/data/real_restaurants.json` chứa các đối tượng có tên và amenity thuộc
restaurant, fast_food, cafe, food_court, ice_cream trong ranh giới Việt Nam của
snapshot OSM. Importer bỏ đối tượng gắn disused/abandoned/private, geometry thiếu
và trùng tên/tọa độ theo quy tắc được ghi trong script.

Không khẳng định đã có mọi quán thực tế hoặc quán vẫn hoạt động. Danh mục được
phân loại từ tên và cuisine tag, không phải menu đã được chủ quán xác nhận.
Giá, rating, review count, ảnh được giữ trống khi không có nguồn phù hợp; không
dùng ảnh demo/ảnh stock để giả làm ảnh quán thật. Giờ mở cửa là dữ liệu tham khảo,
không suy diễn trạng thái đang mở. Nhãn tỉnh/khu vực OSM không thay thế danh bạ
hành chính chính thức; thông tin thiếu được ghi rõ.

## Cập nhật catalog

### Ảnh thật tại quán — cập nhật 04/11/2026

Đã bổ sung **9 ảnh cho 9 địa điểm** trong tổng số 18.668 bản ghi, tại Hà Nội,
TP.HCM, Hội An và Đà Nẵng. Ảnh đến từ Wikimedia Commons, đối chiếu tên/quán,
địa chỉ hoặc tọa độ của đúng chi nhánh; không dùng logo chung để gán cho cả chuỗi.
Không khẳng định đã có ảnh cho tất cả quán hoặc ảnh phản ánh diện mạo hiện nay.
Một số ảnh lịch sử khá cũ; ngày chụp theo nguồn được hiển thị trong thông tin ảnh.

Vào **Khám phá → Có ảnh tại quán** để lọc các địa điểm đã có ảnh. Chạm dòng
ghi tác giả/giấy phép trên ảnh để xem chú thích, ngày chụp, nguồn gốc và giấy phép.
Quán chưa có ảnh đã đối chiếu vẫn dùng ảnh món ăn có nhãn minh họa, kèm thông báo
trong chi tiết. Ảnh thật được đóng gói offline, không phụ thuộc URL tạm thời.

- `assets/data/restaurant_photos.json`: ID quán, đường dẫn ảnh, tác giả, giấy phép,
  URL nguồn, ngày chụp, bằng chứng đối chiếu và SHA-256 của từng ảnh.
- `assets/venue_photos/CREDITS.md`: attribution riêng cho ảnh, độc lập giấy phép OSM.
- `tool/data/venue_photo_sources.json`: danh sách đối chiếu trước khi tải.
  Đổi tên/địa chỉ quán trong lần cập nhật catalog cần xem lại ảnh; app không gán
  ảnh cũ khi tên doanh nghiệp tại cùng OSM ID đã thay đổi.

Tải lại sau khi duyệt danh sách nguồn:

```powershell
python tool/data/import_venue_photos.py
python -m unittest discover -s tool/data -p test_import_venue_photos.py -v
flutter test test/restaurant_photos_test.dart
```

Importer chỉ nhận các giấy phép mở đã cho phép trong mã, lưu tác giả và liên kết
giấy phép theo từng file. Ảnh chỉ được thu nhỏ bởi Commons và cắt theo khung khi
hiển thị. [Hướng dẫn tái sử dụng của Commons](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia).

### Dữ liệu quán OSM

```powershell
python -m pip install -r tool/data/requirements.txt
curl.exe -L --fail https://download.geofabrik.de/asia/vietnam-latest.osm.pbf -o D:\devtools\data\vietnam-latest.osm.pbf
curl.exe -L --fail https://download.geofabrik.de/asia/vietnam-latest.osm.pbf.md5 -o D:\devtools\data\vietnam-latest.osm.pbf.md5
$osmExpectedMd5 = (Get-Content D:\devtools\data\vietnam-latest.osm.pbf.md5 -Raw).Split(' ')[0].Trim()
$osmActualMd5 = (Get-FileHash D:\devtools\data\vietnam-latest.osm.pbf -Algorithm MD5).Hash
if ($osmActualMd5 -ine $osmExpectedMd5) { throw 'Checksum OSM không khớp; tải lại snapshot và MD5 cùng phiên bản.' }
python tool/data/import_osm.py D:\devtools\data\vietnam-latest.osm.pbf
python -m unittest discover -s tool/data -p test_import_osm.py -v
```

Đối chiếu MD5 của cùng snapshot trước khi import. Importer đọc ba lượt streaming
để không giữ toàn bộ node Việt Nam trong RAM. Quán là polygon dùng điểm đại diện
nằm trong geometry, không lấy tọa độ tùy ý. Quan hệ polygon được lắp từ member
ways, xử lý inner rings, và ghép tỉnh/khu vực bằng spatial lookup.

Script chỉ thay catalog sau khi tạo xong dữ liệu hợp lệ. Manifest giữ checksum,
snapshot timestamp, số bản ghi, thống kê loại bỏ và số lượng theo nhãn tỉnh.
Không thu thập tên, user ID hoặc changeset ID của người đóng góp OSM.

## Liên kết TikTok/Maps

Mỗi quán có nút chỉ đường Google Maps và tìm kiếm TikTok; URL tìm kiếm không được
coi là video review hay bằng chứng đã có video đúng chi nhánh.

Liên kết trực tiếp được lấy từ tag TikTok của nguồn nếu có, hoặc bổ sung thủ công
trong `assets/data/source_links.json`. Map `restaurants` dùng ID ổn định
`osm-node-...`, `osm-way-...`, `osm-relation-...`. Mỗi entry cần `checkedAt`
(ngày đối chiếu) và `links` gồm platform, URL HTTPS chuẩn và label. Phải đối chiếu
đúng tên/địa chỉ/chi nhánh trước khi thêm; ngày nhập không chứng minh nội dung là
đánh giá xác thực. App từ chối host giả mạo, scheme nguy hiểm và ID không tồn tại.

Không tải lại video/ảnh creator vào APK, không cần đăng nhập TikTok trong app.
Việc mở TikTok/Maps đưa người dùng sang dịch vụ ngoài với chính sách riêng.

## Chạy và kiểm thử

```powershell
flutter pub get
flutter analyze
flutter test
flutter test integration_test/open_data_flow_test.dart -d emulator-5554 --no-uninstall
flutter build apk --debug
```

Các integration test cũ dùng dữ liệu demo cần thêm
`--dart-define=RESTAURANT_DATA=demo`. Không chạy test demo rồi suy ra catalog thật
đã được kiểm tra. Test dữ liệu thật dùng quán và tọa độ từ catalog hiện có.

## Bản kiểm tra ngày 30/10/2026

- 18.668 địa điểm có tên; snapshot nguồn `2026-10-29T21:21:26Z`.
- 2 link TikTok trực tiếp có sẵn trong OSM; những quán khác dùng nút tìm kiếm.
- Toàn bộ giá/rating còn thiếu được giữ null; ảnh thật chưa có được ghi rõ.
- `flutter analyze`: không có vấn đề; 51 unit/widget tests và 3 importer tests đạt.
- Integration test dữ liệu thật đạt trên Android API 36 khi Wi-Fi/mobile data
  đều tắt: chọn quán, xem nguồn và nút TikTok, lưu yêu thích, khôi phục theme.
- Sau khi khởi động lại Android và cài APK app thường, theme tối, khu vực Ba Đình
  và quán yêu thích vẫn được giữ. Nút TikTok đã mở trình duyệt với host chính xác.
- APK đóng gói từ `lib/main.dart`, đã đối chiếu catalog trong APK với file nguồn:
  [hom_nay_an_gi-open-data-debug.apk](../artifacts/hom_nay_an_gi-open-data-debug.apk),
  234.699.964 byte, SHA-256
  `bed91da6a295550091e277d9f6c90225195fbcc15d477a2433ac2f640e85e3ce`.

Ảnh từ APK app thường: [Trang chủ](../artifacts/open-data-home.png),
[yêu thích sau khởi động lại](../artifacts/open-data-favorites-after-restart.png),
[nguồn và TikTok/Maps](../artifacts/open-data-source-links.png).

APK demo và ảnh trong báo cáo cũ không phải bằng chứng cho catalog thật này.

## Giấy phép và nguồn chính thức

Catalog dẫn xuất được phân phối ở dạng JSON có thể sửa, kèm provenance và
attribution © OpenStreetMap contributors, ODbL 1.0. Giữ các thông tin này khi
phân phối dữ liệu; xem `assets/data/DATA_LICENSE.md`. Ghi chú dữ liệu không đổi
giấy phép của source code ứng dụng độc lập.

- [Geofabrik Vietnam](https://download.geofabrik.de/asia/vietnam.html)
- [OpenStreetMap copyright](https://www.openstreetmap.org/copyright)
- [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/)
- [Google Places policies](https://developers.google.com/maps/documentation/places/web-service/policies)
- [TikTok Display API](https://developers.tiktok.com/docs/en/display-api-overview)
