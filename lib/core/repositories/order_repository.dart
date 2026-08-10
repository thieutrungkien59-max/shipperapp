import 'package:latlong2/latlong.dart';

import '../../models/don_hang_model.dart';
import '../../models/shipping_quote_model.dart';
import '../../services/api_service.dart';

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
        return (response['\$values'] as List)
            .map((json) => DonHangModel.fromJson(json))
            .toList();
      } else if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => DonHangModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'API trả về Object nhưng không tìm thấy mảng. Nội dung: $response',
        );
      }
    }
    // Kịch bản 3: Các trường hợp khác
    else {
      throw Exception(
        'Dữ liệu từ Server không đúng chuẩn danh sách. Kiểu thực tế: ${response.runtimeType}',
      );
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

  // LẤY ĐƠN ADMIN ĐÃ CHỈ ĐỊNH RIÊNG CHO SHIPPER NÀY
  // Trạng thái backend: ChoShipperXacNhan.
  Future<List<DonHangModel>> getAssignedOrdersWaitingConfirmation(
    String maShipper,
  ) async {
    try {
      final response = await _apiService.get(
        '/api/DonHang/shipper/$maShipper/cho-xac-nhan',
      );
      return _parseOrderList(response);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // SHIPPER TỰ NHẬN ĐƠN TỪ POOL ChoXacNhan.
  //
  // Backend sẽ:
  // - kiểm tra Shipper online + hồ sơ đã duyệt;
  // - kiểm tra tải trọng còn lại;
  // - atomically claim đơn nếu nó vẫn còn ChoXacNhan;
  // - gán MaSp và chuyển thẳng sang DaXacNhan.
  Future<void> selfAcceptAvailableOrder({
    required String maDonHang,
    required String maShipper,
  }) async {
    try {
      await _apiService.post('/api/DonHang/shipper-tu-nhan-don', {
        'maDonHang': maDonHang,
        'maShipper': maShipper,
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // SHIPPER NHẬN / TỪ CHỐI ĐƠN ĐÃ ĐƯỢC ADMIN CHỈ ĐỊNH.
  Future<void> respondToAssignedOrder({
    required String maDonHang,
    required String maShipper,
    required bool chapNhan,
    String? lyDo,
  }) async {
    try {
      await _apiService.post('/api/DonHang/shipper-phan-hoi-don', {
        'maDonHang': maDonHang,
        'maShipper': maShipper,
        'chapNhan': chapNhan,
        'lyDo': lyDo,
      });
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

  // UPLOAD MINH CHỨNG GIAO/LẤY HÀNG (ảnh + OTP hoặc chữ ký)
  Future<bool> uploadDeliveryProof({
    required String maDonHang,
    required String hinhAnhUrl,
    required String chuKyOtp,
  }) async {
    try {
      final body = {
        "maDonHang": maDonHang,
        "hinhAnhUrl": hinhAnhUrl,
        "chuKyOtp": chuKyOtp,
      };

      await _apiService.post('/api/DonHang/upload-minh-chung', body);
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // BÁO GIAO HÀNG THẤT BẠI
  Future<bool> reportDeliveryFailure({
    required String maDonHang,
    required String maShipper,
    required String lyDo,
  }) async {
    try {
      final body = {
        "maDonHang": maDonHang,
        "maShipper": maShipper,
        "lyDo": lyDo,
      };

      await _apiService.post('/api/DonHang/bao-giao-that-bai', body);
      return true;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // TÍNH TUYẾN ĐƯỜNG BỘ THẬT (qua OSRM) + PHÍ VẬN CHUYỂN GIỮA 2 TOẠ ĐỘ.
  // Dùng để vẽ tuyến đường thật cho Shipper thay vì mô phỏng, y hệt cách app
  // người dùng đang dùng (POST /api/DonHang/tinh-phi-van-chuyen).
  Future<ShippingQuoteModel> calculateShippingRoute({
    required LatLng pickup,
    required LatLng delivery,
  }) async {
    try {
      final body = {
        "viDoLay": pickup.latitude,
        "kinhDoLay": pickup.longitude,
        "viDoGiao": delivery.latitude,
        "kinhDoGiao": delivery.longitude,
      };

      final response = await _apiService.post(
        '/api/DonHang/tinh-phi-van-chuyen',
        body,
      );
      if (response is! Map) {
        throw Exception('Backend trả dữ liệu tính tuyến đường không hợp lệ.');
      }
      return ShippingQuoteModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // GỬI OTP THẬT tới SĐT khách hàng.
  // LƯU Ý: Backend hiện đang ở chế độ TEST — chưa thật sự bắn SMS qua nhà mạng,
  // mà trả thẳng mã OTP về trong response (field "maOtp") để app hiển thị test.
  // Khi Backend nối nhà mạng SMS thật, có thể maOtp sẽ không còn được trả về nữa
  // (khi đó hàm này vẫn hoạt động, chỉ là chuỗi trả về sẽ rỗng/không dùng được).
  Future<String> sendOtp(String soDienThoai) async {
    try {
      final response = await _apiService.post('/api/DonHang/gui-otp', {
        "soDienThoai": soDienThoai,
      });
      if (response is Map && response['maOtp'] != null) {
        return response['maOtp'].toString();
      }
      return '';
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
