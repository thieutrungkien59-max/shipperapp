import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final ApiServices _apiService;

  AuthRepository(this._apiService);

  // Hàm xử lý đăng nhập Shipper
  Future<bool> login(String username, String password) async {
    try {
      final body = {
        "username": username,
        "password": password
      };
      
      // Gọi đến endpoint đăng nhập
      final response = await _apiService.post('/api/Auth/login', body);
      
      // Trích xuất dữ liệu từ phản hồi của Backend
      final maTk = response['maTk']; // BỔ SUNG LẤY MÃ TÀI KHOẢN
      final thongTin = response['thongTinChiTiet'];
      final maSp = thongTin['maSp'];

      // Lưu vào bộ nhớ cục bộ của điện thoại
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('maTk', maTk); // BỔ SUNG LƯU MÃ TÀI KHOẢN
      await prefs.setString('maSp', maSp); 
      
      // Tạm thời trả về true nếu không có lỗi văng ra
      return true; 
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

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
        "taiTrongToiDa": taiTrongToiDa
      };
      
      await _apiService.post('/api/Auth/register-shipper', body);
      return true; 
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }
}