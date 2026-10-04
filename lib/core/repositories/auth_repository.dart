import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../config/app_config.dart';
import '../demo/demo_delivery_store.dart';

class AuthRepository {
  final ApiServices _apiService;

  AuthRepository(this._apiService);

  // Hàm xử lý đăng nhập Shipper
  Future<bool> login(String username, String password) async {
    try {
      if (AppConfig.demoMode) {
        await SessionService.saveSession(
          accountId: 'DEMO-ACCOUNT-01',
          driverId: DemoDeliveryStore.instance.driverId,
          accessToken: 'demo-token-not-for-production',
          userName: 'Tài xế Demo',
          userRole: 'DRIVER',
        );
        return true;
      }
      final body = {'username': username, 'password': password};
      dynamic response;

      try {
        response = await _apiService.post('/api/identity/login', body);
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
        response = await _apiService.post('/api/Auth/login', body);
      }

      // Trích xuất dữ liệu từ phản hồi của Backend
      final responseMap = Map<String, dynamic>.from(response as Map);
      final rawUser = responseMap['user'] ?? responseMap['data'] ?? responseMap;
      final user = Map<String, dynamic>.from(rawUser as Map);
      final rawDetail = user['chiTiet'] ?? user['profile'] ?? const {};
      final chiTiet = Map<String, dynamic>.from(rawDetail as Map);
      final maTk = (user['maTk'] ?? user['id'] ?? user['userId'] ?? '')
          .toString();
      final maSp = (chiTiet['maSp'] ?? user['maSp'] ?? user['driverId'] ?? '')
          .toString();
      final token =
          (responseMap['accessToken'] ??
                  responseMap['token'] ??
                  responseMap['jwt'])
              ?.toString();

      if (maTk.isEmpty || maSp.isEmpty) {
        throw Exception('Backend đăng nhập chưa trả đủ user id và driver id.');
      }

      await SessionService.saveSession(
        accountId: maTk,
        driverId: maSp,
        accessToken: token,
        userName: (user['hoTen'] ?? user['name'])?.toString(),
        userRole: (user['role'] ?? user['vaiTro'])?.toString(),
      );

      // Tạm thời trả về true nếu không có lỗi văng ra
      return true;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  Future<void> logout() => SessionService.clear();

  // Hàm xử lý đăng ký Shipper mới
  Future<bool> register({
    required String hoTen,
    required String soDienThoai,
    required String password,
    required String cccd,
    required String gplx,
    required String bienSoXe,
    required String loaiPhuongTien,
    required int taiTrongToiDa,
  }) async {
    try {
      final body = {
        "tenDangNhap": soDienThoai,
        "matKhau": password,
        "hoTen": hoTen,
        "soDienThoai": soDienThoai,
        "cccd": cccd,
        "gplx": gplx,
        "bienSoXe": bienSoXe,
        "loaiPhuongTien": loaiPhuongTien,
        "taiTrongToiDa": taiTrongToiDa,
      };

      await _apiService.post('/api/Auth/register-shipper', body);
      return true;
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // Hàm cập nhật thông tin hồ sơ Shipper
  Future<bool> updateShipperProfile({
    required String maSp,
    required String hoTen,
    required String soDienThoai,
    required String cccd,
    required String gplx,
    required String bienSoXe,
    required String loaiPhuongTien,
    required int taiTrongToiDa,
  }) async {
    try {
      final body = {
        "hoTen": hoTen,
        "soDienThoai": soDienThoai,
        "cccd": cccd,
        "gplx": gplx,
        "bienSoXe": bienSoXe,
        "loaiPhuongTien": loaiPhuongTien,
        "taiTrongToiDa": taiTrongToiDa,
      };

      await _apiService.put('/api/Auth/update-shipper/$maSp', body);
      return true;
    } catch (e) {
      throw Exception('Lỗi cập nhật hồ sơ: $e');
    }
  }
}
