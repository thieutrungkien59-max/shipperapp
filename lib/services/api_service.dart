import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  // Đường dẫn gốc gọi đến Backend Swagger (Local IP)
  static const String baseUrl = 'https://startle-kilogram-greeting.ngrok-free.dev';

  // Cấu hình Header mặc định cho mọi Request
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      // 'Authorization': 'Bearer $token', // Bỏ comment dòng này khi có Token đăng nhập
    };
  }

  // Hàm xử lý phương thức GET
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(url, headers: _buildHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // Hàm xử lý phương thức POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // Hàm xử lý lỗi tập trung dựa vào Status Code
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Thành công: Chuyển đổi chuỗi JSON thành đối tượng Dart
      return jsonDecode(response.body);
    } else {
      // Thất bại: Bắt các mã lỗi phổ biến và quăng Exception
      switch (response.statusCode) {
        case 400:
          throw Exception('Yêu cầu không hợp lệ (400)');
        case 401:
          throw Exception('Sai tài khoản/mật khẩu hoặc hết phiên đăng nhập (401)');
        case 403:
          throw Exception('Không có quyền truy cập (403)');
        case 404:
          throw Exception('Không tìm thấy dữ liệu (404)');
        case 500:
          throw Exception('Lỗi máy chủ nội bộ (500)');
        default:
          throw Exception('Đã xảy ra lỗi: ${response.statusCode}');
      }
    }
  }
}