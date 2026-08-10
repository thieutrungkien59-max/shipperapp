# Bàn giao kỹ thuật — ShipperApp

> Phiên bản khảo sát: 10/08/2026. Tài liệu này được lập từ toàn bộ mã nguồn đang có trong repository, không xác nhận được trạng thái thực của backend/ngrok hay thiết bị thật.

## 1. Tóm tắt hiện trạng

**ShipperApp** là ứng dụng Flutter cho tài xế/shipper vận hành giao nhận. Ứng dụng đã có UI và phần lớn luồng nghiệp vụ phía client: đăng ký/đăng nhập, online/offline, nhận đơn do admin chỉ định, theo dõi GPS, chỉ đường trên bản đồ, xác nhận lấy/giao hàng bằng ảnh + chữ ký, báo giao thất bại, hồ sơ và đối soát COD.

Kiến trúc hiện tại là Flutter thuần, theo kiểu feature + repository đơn giản. Mỗi màn hình tự tạo `ApiServices`/repository, tự quản lý state bằng `StatefulWidget`; không dùng Provider/BLoC/Riverpod, DI, router tập trung hay lớp domain/use-case. Backend REST là nguồn dữ liệu chính nhưng không nằm trong repository này.

Đánh giá ngắn: đây là **prototype/MVP đã nối một phần API**, chưa đạt mức sẵn sàng production. Các rủi ro lớn nhất là không có xác thực token, cấu hình/backend hard-code, fallback tuyến đường mô phỏng, thiếu test, và một số màn hình còn mock/chưa nối luồng.

## 2. Công nghệ và cách chạy

| Hạng mục | Hiện trạng |
|---|---|
| Framework | Flutter/Dart, SDK Dart `^3.11.5` |
| App version | `0.1.0+1` |
| Nền tảng scaffold | Android, iOS, Web, Windows, Linux, macOS |
| HTTP | `http ^1.6.0` |
| Bản đồ | `flutter_map ^7.0.2`, `latlong2` transitively/directly used |
| GPS | `geolocator ^13.0.2` |
| Định tuyến | Backend gọi OSRM qua endpoint tính phí/tuyến đường; app có fallback tự mô phỏng |
| Camera | `camera ^0.11.0+2` |
| Local storage | `shared_preferences ^2.1.1` |
| Gọi điện | `url_launcher ^6.3.1`, mở scheme `tel:` |
| Lệnh cơ bản | `flutter pub get`, sau đó `flutter run` |

Không có asset nghiệp vụ, test Dart/Flutter, CI, env file, flavor, signing release hoặc tài liệu setup backend. `README.md` vẫn là nội dung mặc định của Flutter.

## 3. Cấu trúc mã nguồn

```text
lib/
  main.dart                         # Entry point; luôn mở LoginScreen
  services/
    api_service.dart                 # HTTP client dùng chung
    location_service.dart            # Quyền GPS, current position, position stream
    firebase_auth_service.dart       # Trống, không dùng Firebase
  models/
    don_hang_model.dart              # Model đơn hàng + parser tolerant nhiều format API
    shipping_quote_model.dart        # Tuyến đường/phí từ backend
    vi_cod_model.dart                # Ví COD và phiếu đối soát
    shipper_model.dart               # Trống
  core/
    repositories/                    # auth, order, shipper GPS, ví COD
    routes/app_routes.dart           # Route cũ/chưa dùng làm router chính
    utils/                           # gọi điện, mô phỏng route; format_utils trống
    constants/, constans/            # Hai thư mục trùng/đều gần như trống
  features/
    auth/                            # login, register; otp_screen trống
    home/                            # dashboard 4 tab + online/polling/GPS
    orders/                          # nhận đơn, danh sách, bản đồ chi tiết, thất bại, bàn giao
    map_tracking/                    # màn giao hàng và full-screen map
    order_proof/                     # camera + ký tay + upload proof
    wallet_cod/                      # ví COD/phiếu nộp
    profile/                         # xem/sửa hồ sơ và trạng thái trực tuyến
```

Các file UI rất lớn (Home 877 dòng, MapDelivery 978, Wallet 710, Proof 648) nên logic, state, gọi API và layout đang gộp vào cùng file. Đây là điểm cần tách khi tiếp tục phát triển.

## 4. Khởi động, điều hướng và dữ liệu cục bộ

- `main.dart` tạo `MaterialApp`, theme đỏ mặc định, không dùng named routes; `home` là `LoginScreen`.
- Sau login thành công, `LoginScreen` điều hướng xóa stack sang `HomeScreen`.
- `HomeScreen` giữ bốn tab nội bộ: Trang chủ, Đơn hàng (`OrderListTab`), Đối soát (`FinanceTab`), Hồ sơ (`ProfileScreen`).
- Hầu hết chuyển màn dùng `MaterialPageRoute`; `AppRoutes` chỉ khai báo `/login`, `/home`, `/orders` và route tới `OrderListScreen` cũ dùng mock. `MaterialApp` chưa gắn `onGenerateRoute`, vì vậy `AppRoutes` thực tế gần như không có hiệu lực.
- `SharedPreferences` lưu hai chuỗi sau đăng nhập: `maTk` (mã tài khoản) và `maSp` (mã shipper). Không lưu token, thời hạn phiên, hồ sơ hay trạng thái app.
- Không có logout thực sự: không thấy xóa `SharedPreferences`, thu hồi token hoặc trở về login trong luồng hiện tại.

## 5. API client và hợp đồng backend suy ra từ code

`ApiServices` ghép endpoint vào một base URL ngrok hard-code. Header JSON có `ngrok-skip-browser-warning`; Authorization Bearer chỉ là dòng comment. HTTP hỗ trợ GET/POST/PUT, decode JSON, và chuyển các status phổ biến 400/401/403/404/500 thành Exception tiếng Việt. Không có timeout, retry, interceptor, refresh token, multipart upload hay logging có cấu trúc.

| Nhóm | Endpoint được app gọi | Mục đích / payload quan trọng |
|---|---|---|
| Auth | `POST /api/Auth/login` | `{username,password}`; app kỳ vọng `response.user.maTk`, `response.user.chiTiet.maSp` |
| Auth | `POST /api/Auth/register-shipper` | Tên, SĐT, mật khẩu, CCCD, GPLX, biển số, loại xe, tải trọng |
| Profile | `GET /api/Auth/profile/{maTk}` | UI kỳ vọng `chiTiet` có dữ liệu shipper và `trangThaiHoatDong` |
| Profile | `PUT /api/Auth/update-shipper/{maSp}` | Cập nhật thông tin shipper/xe |
| Shipper | `POST /api/Shipper/doi-trang-thai-hoat-dong` | `{maShipper,trangThaiMoi}`: `TrucTuyen` / `NgoaiTuyen` |
| Shipper | `POST /api/Shipper/cap-nhat-gps` | `{maShipper,kinhDo,viDo}` |
| Đơn | `GET /api/DonHang/danh-sach-cho-nhan` | Pool đơn chờ nhận; hiện repository có nhưng UI Home chủ yếu dùng đơn admin chỉ định |
| Đơn | `GET /api/DonHang/shipper/{maSp}/cho-xac-nhan` | Danh sách admin chỉ định, trạng thái `ChoShipperXacNhan` |
| Đơn | `POST /api/DonHang/shipper-phan-hoi-don` | `{maDonHang,maShipper,chapNhan,lyDo}` |
| Đơn | `GET /api/DonHang/shipper/{maSp}` | Danh sách đơn thuộc shipper |
| Đơn | `GET /api/DonHang/chi-tiet/{maDh}` | Chi tiết đơn |
| Đơn | `POST /api/DonHang/cap-nhat-trang-thai` | `{maDonHang,trangThaiMoi,maShipper,ghiChu}` |
| Đơn | `POST /api/DonHang/upload-minh-chung` | `{maDonHang,hinhAnhUrl,chuKyOtp}`; hiện cả hai thực chất là data URI base64 |
| Đơn | `POST /api/DonHang/bao-giao-that-bai` | `{maDonHang,maShipper,lyDo}` |
| Đơn | `POST /api/DonHang/tinh-phi-van-chuyen` | `{viDoLay,kinhDoLay,viDoGiao,kinhDoGiao}`; trả route/phí |
| Đơn | `POST /api/DonHang/gui-otp` | `{soDienThoai}`; backend test được ghi chú là trả OTP trong `maOtp` |
| COD | `GET /api/DoiSoat/vi-cod/{maSp}` | Ví COD của shipper |
| COD | `GET /api/canhbao/cod/count` | Tổng số cảnh báo COD, không thấy lọc shipper |
| COD | `POST /api/DoiSoat/tao-phieu` | `{maShipper,tongTienNop}` |
| COD | `GET /api/DoiSoat/danh-sach-phieu-cho-duyet` | Toàn bộ phiếu chờ duyệt; client tự lọc theo `maSp` |

`DonHangModel.fromJson` cố ý chịu được hai schema (`maDh`/`maDon`/`id`, `diaChiLay`/`diemLayHang`, `khoiLuong`/`trongLuong`, các tên SĐT khác nhau) và list API trực tiếp, `data`, hoặc `$values`. Đây là dấu hiệu backend chưa chuẩn hóa response; giữ lại tính tương thích này nếu chưa sửa đồng thời backend.

## 6. Chức năng đã có

### 6.1 Tài khoản và hồ sơ

- Đăng nhập form username/password; validate UI; gọi API rồi lưu `maTk`, `maSp` local.
- Đăng ký shipper với thông tin định danh/xe/tải trọng và kiểm tra input cơ bản.
- Xem profile qua API: tên, SĐT, CCCD, GPLX, biển số, loại xe, tải trọng, trạng thái phê duyệt/hoạt động và các chỉ số hiển thị.
- Sửa profile, gọi `PUT /update-shipper/{maSp}`.
- Bật/tắt online ở cả Home và Profile; cập nhật backend trạng thái `TrucTuyen`/`NgoaiTuyen`.

### 6.2 Online, GPS và điều phối

- Home khởi tạo ở offline, tự gọi API đổi offline khi `initState`; khi app vào trạng thái `detached` cũng cố gửi offline.
- Online: tải đơn chờ xác nhận, bắt đầu polling đơn admin chỉ định mỗi 5 giây, lấy GPS ngay và theo dõi tiếp mỗi 15 m để gửi lên admin.
- Chống mở popup trùng bằng `_notifiedOrderIds`, và chỉ mở một popup nhận đơn tại một thời điểm.
- Popup đơn được admin phân trực tiếp dẫn sang `OrderAcceptScreen`.
- `LocationService` kiểm tra GPS bật/tắt và yêu cầu quyền vị trí, có message lỗi tiếng Việt.

### 6.3 Nhận và xử lý đơn

- Màn nhận đơn tải song song chi tiết đơn và profile để so trọng lượng với `taiTrongToiDa`.
- Có countdown 30 giây, nhận hoặc từ chối/timeout qua `shipper-phan-hoi-don`; nhận thành công mở `MapDeliveryScreen`.
- Tab đơn thật (`OrderListTab`) gọi `GET /shipper/{maSp}`, phân nhóm đang xử lý (`DaXacNhan`,`DangGiao`), hoàn tất (`DaGiao`) và thất bại/hủy (`GiaoThatBai`,`DaHuy`,`HuyTraHang`).
- Màn chi tiết hiển thị stepper, địa chỉ, kiện hàng, COD/phí, snapshot bản đồ và cho mở luồng giao.

### 6.4 Bản đồ, route và GPS trong chuyến

- `MapDeliveryScreen` tải chi tiết đơn; pha giao được suy ra từ `trangThai == DangGiao`.
- Theo dõi GPS liên tục, hiển thị marker vị trí shipper, gửi vị trí lên backend có giới hạn thời gian gửi để không spam (bổ sung thêm giới hạn trong màn map).
- Nếu đơn có tọa độ thực, gọi API route/phí (backend OSRM) từ vị trí hiện tại đến điểm lấy/giao, vẽ polyline bằng `flutter_map` và hiển thị distance/ETA.
- Nếu thiếu tọa độ hoặc API route lỗi, dùng `RouteSimulator`: sinh điểm quanh TP.HCM theo seed đơn và vẽ route/distance **mô phỏng**. UI có cờ phân biệt mô phỏng/thật.
- Có màn `FullMapScreen`, recenter và nút chỉ đường trong UI.

### 6.5 Xác nhận lấy/giao, thất bại và bàn giao

- Luồng map cập nhật trạng thái: lấy hàng thành công chuyển sang `DangGiao`, hoàn tất giao chuyển `DaGiao`; đều yêu cầu chứng từ trước khi cập nhật trạng thái.
- `CameraCaptureScreen` dùng camera thiết bị, trả `Uint8List`; `CameraProofScreen` yêu cầu chụp ảnh kiện + chữ ký tay, cho gọi người gửi/nhận, raster hóa chữ ký từ `RepaintBoundary`, encode ảnh/chữ ký thành data URI rồi gọi upload proof.
- Báo giao thất bại có 5 lý do, bắt buộc ghi chú nếu “Khác”; sau post sẽ fetch lại chi tiết để quyết định còn giao tiếp hay server đã chuyển thất bại.
- Có UI bàn giao giữa shipper, UI giả lập QR/OTP và ảnh; submit hiện chỉ gọi generic update-status.

### 6.6 Ví COD

- Đọc ví COD, số dư, hạn mức và trạng thái; hiển thị cảnh báo.
- Cho nhập số tiền nộp, chọn tiền mặt/chuyển khoản; QR chỉ là placeholder UI.
- Kiểm tra phiếu chờ duyệt trước khi tạo phiếu mới nhằm tránh nộp trùng.

## 7. Chưa hoàn thiện / cần xác nhận

| Mức độ | Hạng mục | Hiện trạng chính xác |
|---|---|---|
| Cao | Xác thực/phiên | Không có Bearer token trong request; login chỉ lưu 2 mã; không logout, refresh token, expiry hay guard route. |
| Cao | Bí mật cấu hình | Android Manifest chứa Google Maps API key plaintext; base URL ngrok hard-code. Key cần revoke/rotate và đưa sang env/secret management. |
| Cao | Production Android | `applicationId` là `com.example.shipperapp`, release ký bằng debug key, package/app name còn default. |
| Cao | Điều phối đơn | UI dùng đơn admin chỉ định; endpoint “pool đơn chờ nhận” tồn tại nhưng chưa thấy có flow nhận pool. Cần chốt nghiệp vụ. |
| Cao | Tính đúng đắn route | Thiếu tọa độ/API route sẽ hiện tuyến đường ngẫu nhiên quanh TP.HCM. Không được dùng để điều hướng hay tính phí production. |
| Cao | Proof upload | Ảnh và chữ ký base64 trong JSON, field `chuKyOtp` bị dùng để truyền ảnh chữ ký; không resize/nén thực tế dù UI nói max 2MB, dễ quá payload. Cần endpoint multipart/storage URL và schema rõ ràng. |
| Cao | Bàn giao đơn | QR/OTP và ảnh chỉ thay bool UI, không xác thực thật hoặc upload ảnh. Mã đơn/tên shipper có default hard-code; trạng thái `DaBanGiao` chỉ là giả định. |
| Cao | Backend contract | Các status `DaXacNhan`, `DangGiao`, `DaBanGiao`, schema reason và payload proof đều có note cần xác nhận. Cần OpenAPI/contract test trước khi mở rộng. |
| Trung bình | Màn đơn cũ | `order_list_screen.dart` dùng `_mockOrders` và `OrderItem` riêng; route `/orders` vẫn dẫn vào màn này, khác với `OrderListTab` đã dùng API. Nên xóa/replace hoặc không expose. |
| Trung bình | OTP | Có repository `sendOtp` nhưng không có `otp_screen` (file trống) và proof hiện dùng chữ ký thay OTP; backend được ghi chú đang trả OTP plaintext trong test. |
| Trung bình | Offline/lifecycle | Bật app luôn ép shipper offline; chỉ xử lý lifecycle `detached`, không xử lý background/paused/resumed đầy đủ. Update GPS không có background service, queue, retry hoặc idempotency. |
| Trung bình | COD | API cảnh báo và danh sách phiếu lấy toàn hệ thống rồi client lọc; có nguy cơ hiệu năng/lộ dữ liệu. QR/chuyển khoản chưa tích hợp ngân hàng; không có lịch sử đối soát. |
| Trung bình | Code structure | State/API/layout gộp trong screen, màu lặp cục bộ; `AppRoutes` không nối main; dependency injection và quản lý lỗi/loading chưa thống nhất. |
| Trung bình | Quyền nền tảng | Android có location/camera; iOS có camera và `tel` nhưng không thấy `NSLocationWhenInUseUsageDescription`. Cần kiểm tra thêm config location cho iOS và điều kiện Android target SDK. |
| Thấp | File chết/trống | `firebase_auth_service.dart`, `shipper_model.dart`, `format_utils.dart`, hai `app_colors.dart` trống; thư mục `constans` sai chính tả song song `constants`. |
| Thấp | Encoding | Một số comment/chuỗi hiển thị bị mojibake khi đọc theo encoding console. Hãy chuẩn hóa UTF-8 không BOM và kiểm tra hiển thị tiếng Việt trên thiết bị. |

## 8. Trạng thái chất lượng và kiểm thử

- Không có thư mục `test/` hay test widget/unit/integration tự viết. iOS chỉ có `RunnerTests` mẫu.
- `flutter analyze` được chạy trong lúc khảo sát nhưng không hoàn tất trong giới hạn 60 giây của môi trường, nên tài liệu này không kết luận analyzer pass/fail. Cần chạy lại cục bộ/CI với timeout phù hợp.
- `analysis_options.yaml` chỉ include `flutter_lints`.
- Worktree tại thời điểm khảo sát có thay đổi chưa commit ở generated plugin registrants cho Linux/macOS/Windows và file mới `devtools_options.yaml`; chúng không liên quan trực tiếp tới feature code. Không tự ý chỉnh/revert các thay đổi đó.
- Lịch sử Git gần nhất cho thấy hướng phát triển: ví COD, map, giao thất bại/bàn giao, online status, login/profile, GPS và admin chỉ định đơn.

## 9. Luồng nghiệp vụ hiện có

```text
Login → lưu maTk/maSp → Home (offline)
  → bật Online → backend TrucTuyen + GPS + poll 5 giây
  → Admin chỉ định đơn (ChoShipperXacNhan)
  → popup → xem đơn → nhận/từ chối (30 giây)
  → Map: đến điểm lấy → chứng từ ảnh + chữ ký → DangGiao
  → Map: đến điểm giao → chứng từ ảnh + chữ ký → DaGiao
  └→ hoặc báo thất bại → backend quyết định tiếp tục / GiaoThatBai

Home tab: Đơn thật theo maSp | Ví COD/phiếu nộp | Profile/sửa hồ sơ
```

## 10. Đề xuất lộ trình cho GPTWeb/đội tiếp quản

### P0 — làm trước khi demo production

1. Chốt OpenAPI với backend: auth response, tất cả enum trạng thái đơn, quyền theo shipper, response list, proof, bàn giao, COD. Xóa các giả định tên status trong app.
2. Thay ngrok/base URL/API key hard-code bằng config theo environment. Rotate API key đã lộ, giới hạn key theo Android app SHA-1/package và iOS bundle; không commit secret.
3. Thêm JWT/session chuẩn vào `ApiServices`, interceptor, timeout, logout và xử lý 401; lưu secure storage thay vì chỉ SharedPreferences.
4. Xóa route mô phỏng khỏi production hoặc buộc gắn nhãn rõ + chặn hành động phụ thuộc route khi không có tọa độ thật. Backend phải trả lat/lng pickup/dropoff hoặc geocode tin cậy.
5. Thiết kế upload file: camera resize/compress, multipart tới object storage, trả URL, link URL với proof; không đẩy base64 lớn trong JSON.
6. Hoàn thiện delivery handover bằng endpoint riêng: xác thực người nhận bàn giao, proof thật, audit log, cập nhật cả người giao/người nhận một cách atomic.

### P1 — ổn định vận hành

1. Tách màn lớn: API/data source → repository → use case/state controller → widget; chọn Riverpod/BLoC/Provider và DI.
2. Chuẩn hóa navigation (GoRouter hoặc `onGenerateRoute` thật), xóa/merge `OrderListScreen` mock, hoàn thiện login persistence/splash/role guard.
3. Tách design token vào một `constants/app_colors.dart` duy nhất; dọn các file trống/sai tên và code dead.
4. GPS: xác định yêu cầu foreground/background, thêm permission platform đầy đủ, throttling server-side, retry/backoff, offline queue và policy pin/riêng tư.
5. COD: API theo shipper, lịch sử phiếu, realtime/polling trạng thái duyệt, tích hợp QR/bank thật hoặc bỏ lựa chọn placeholder.

### P2 — chất lượng và phát hành

1. Viết unit test parser `DonHangModel`, repository/HTTP errors, status mapping; widget/integration test cho login → nhận đơn → proof → hoàn tất.
2. Thêm CI chạy `flutter analyze`, `flutter test`, build Android/iOS; định nghĩa flavor dev/staging/prod.
3. Đổi application ID, tên/icon package, release signing/keystore, policy privacy, crash reporting/analytics, monitoring API.
4. Viết README thật: yêu cầu SDK, biến môi trường, lệnh run, backend contract, test account và checklist release.

## 11. Câu hỏi cần chốt với chủ backend/nghiệp vụ

1. Shipper có được tự nhận đơn từ pool hay chỉ được admin chỉ định? Các trạng thái và quyền chuyển trạng thái chính thức là gì?
2. `DaXacNhan` có nghĩa là đã nhận đơn hay đã lấy hàng? Chính xác thời điểm chuyển sang `DangGiao`, `DaGiao`, `GiaoThatBai`, hủy/trả hàng, bàn giao?
3. Proof bắt buộc theo giá trị COD hay mọi đơn? Proof yêu cầu ảnh, chữ ký, OTP hay kết hợp nào; endpoint upload/retention/audit ra sao?
4. GPS có cần khi app background/đóng? Chu kỳ cập nhật, chính sách battery, quyền riêng tư và backend có xử lý duplicate/out-of-order không?
5. Cách xác thực hiện tại là gì? Login có JWT chưa, roles/authorization server-side thế nào?
6. COD: tiền được tạo/tăng ở nghiệp vụ nào, ai duyệt phiếu, QR/chuyển khoản tích hợp provider nào, và một shipper có thể có bao nhiêu phiếu chờ?
7. Map/routing dùng provider nào cho production, API key sở hữu bởi ai, chi phí/rate limit/cơ chế fallback ra sao?

## 12. Tệp nên đọc đầu tiên khi tiếp quản

1. `lib/services/api_service.dart` và `lib/core/repositories/*.dart` — toàn bộ giao tiếp backend.
2. `lib/models/don_hang_model.dart` — schema dữ liệu và tính tương thích API.
3. `lib/features/home/screens/home_screen.dart` — online/offline, GPS, polling và entry flow chính.
4. `lib/features/orders/screens/order_accept_screen.dart` + `lib/features/map_tracking/screens/map_delivery_screen.dart` — vòng đời xử lý đơn.
5. `lib/features/order_proof/screens/camera_proof_screen.dart` — contract chứng từ hiện hữu.
6. `lib/features/wallet_cod/screens/wallet_screen.dart` — ví/đối soát.

---

Tài liệu này mô tả **client repository hiện hữu**, không thay thế tài liệu API/backend. Khi GPTWeb bắt đầu thay đổi, nên tạo contract backend có version trước, rồi refactor client theo contract đó để tránh tiếp tục nhân đôi các enum/schema tạm thời.
