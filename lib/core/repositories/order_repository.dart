import '../../services/api_service.dart';
import '../../models/don_hang_model.dart';

class OrderRepository {
  final ApiServices _apiService;

  OrderRepository(this._apiService);

  // Hàm dùng chung để bóc tách danh sách đơn hàng từ nhiều kiểu response khác nhau
  List<DonHangModel> _parseOrderList(dynamic response) {
    // Kịch bản 1: API trả về trực tiếp một mảng [...]
    if (response is List) {
      return response.map((json) => DonHangModel.fromJson(json)).toList();
    }
    // Kịch bản 2: API bọc mảng bên trong một Object (Map) {...}
    else if (response is Map<String, dynamic>) {
      // Backend .NET thường bọc list trong biến "$values" hoặc "data"
      if (response.containsKey('\$values') && response['\$values'] is List) {
        return (response['\$values'] as List).map((json) => DonHangModel.fromJson(json)).toList();
      } else if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List).map((json) => DonHangModel.fromJson(json)).toList();
      } else {
        throw Exception('API trả về Object nhưng không tìm thấy mảng. Nội dung: $response');
      }
    }
    // Kịch bản 3: Các trường hợp khác
    else {
      throw Exception('Dữ liệu từ Server không đúng chuẩn danh sách. Kiểu thực tế: ${response.runtimeType}');
    }
  }

  // LẤY DANH SÁCH ĐƠN CHỜ NHẬN (pool đơn "ChoXacNhan", chưa gán cho Shipper nào)
  // -> Dùng cho card "Đơn hàng mới" ở màn Home
  Future<List<DonHangModel>> getOrdersAvailableToAccept() async {
    try {
      final response = await _apiService.get('/api/DonHang/danh-sach-cho-nhan');
      return _parseOrderList(response);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // LẤY DANH SÁCH ĐƠN HÀNG ĐÃ THUỘC VỀ 1 SHIPPER (mọi trạng thái: DaXacNhan, DangGiao, DaGiao...)
  // -> Dùng cho tab Orders (đơn Shipper đang xử lý)
  Future<List<DonHangModel>> getOrdersByShipper(String maShipper) async {
    try {
      final response = await _apiService.get('/api/DonHang/shipper/$maShipper');
      return _parseOrderList(response);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // LẤY CHI TIẾT 1 ĐƠN HÀNG THEO MÃ ĐƠN (dùng cho màn OrderAcceptScreen)
  Future<DonHangModel> getOrderDetail(String maDh) async {
    try {
      final response = await _apiService.get('/api/DonHang/chi-tiet/$maDh');
      return DonHangModel.fromJson(response);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (dùng để Shipper XÁC NHẬN NHẬN ĐƠN, giao thành công, huỷ, v.v.)
  Future<bool> updateOrderStatus(
    String maDonHang,
    String maShipper,
    String trangThaiMoi, {
    String ghiChu = '',
  }) async {
    try {
      final body = {
        "maDonHang": maDonHang,
        "trangThaiMoi": trangThaiMoi,
        "maShipper": maShipper,
        "ghiChu": ghiChu,
      };

      await _apiService.post('/api/DonHang/cap-nhat-trang-thai', body);
      return true; 
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái đơn: $e');
    }
  }
}