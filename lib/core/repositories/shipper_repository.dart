import '../../services/api_service.dart';

class ShipperRepository {
  final ApiServices _apiService;

  ShipperRepository(this._apiService);

  // Gửi vị trí GPS hiện tại của Shipper lên server (để Admin theo dõi trên bản đồ quản trị)
  Future<void> updateGpsLocation({
    required String maShipper,
    required double kinhDo, // longitude
    required double viDo, // latitude
  }) async {
    try {
      final body = {
        "maShipper": maShipper,
        "kinhDo": kinhDo,
        "viDo": viDo,
      };

      await _apiService.post('/api/Shipper/cap-nhat-gps', body);
    } catch (e) {
      // Lỗi cập nhật GPS không nên làm gián đoạn trải nghiệm giao hàng của Shipper
      // (không hiện SnackBar chặn màn hình) -> chỉ ném lỗi để nơi gọi tự quyết định log/bỏ qua.
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}