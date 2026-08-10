import '../../services/api_service.dart';
import '../../models/vi_cod_model.dart';

class ViCodRepository {
  final ApiServices _apiService;

  ViCodRepository(this._apiService);

  // LẤY THÔNG TIN VÍ COD CỦA 1 SHIPPER (số dư, hạn mức, trạng thái, ca làm việc)
  // -> Dùng cho tab Finance (đối soát COD cuối ca)
  Future<ViCodModel> getViCodByShipper(String maShipper) async {
    try {
      final response = await _apiService.get('/api/DoiSoat/vi-cod/$maShipper');
      return ViCodModel.fromJson(response);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // LẤY SỐ LƯỢNG CẢNH BÁO COD (API trả về 1 số nguyên, ví dụ: 0)
  // -> Dùng để hiện banner cảnh báo ở đầu tab Finance
  Future<int> getCanhBaoCodCount() async {
    try {
      final response = await _apiService.get('/api/canhbao/cod/count');
      if (response is int) return response;
      return int.tryParse(response.toString()) ?? 0;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // TẠO PHIẾU NỘP COD (Shipper xác nhận đã nộp tiền cho Quản lý duyệt)
  // -> Dùng cho nút "XÁC NHẬN ĐÃ NỘP" trong tab Finance
  Future<void> createPhieuNop(String maShipper, double tongTienNop) async {
    try {
      final body = {
        "maShipper": maShipper,
        "tongTienNop": tongTienNop,
      };
      await _apiService.post('/api/DoiSoat/tao-phieu', body);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // LẤY DANH SÁCH TẤT CẢ PHIẾU ĐANG CHỜ DUYỆT (toàn hệ thống, không lọc sẵn theo shipper)
  // -> Dùng để kiểm tra: shipper hiện tại đã có phiếu nào đang "ChoDuyet" chưa,
  // tránh tình trạng bấm "Xác nhận đã nộp" nhiều lần tạo trùng phiếu (mỗi phiếu bị
  // trừ tiền riêng khi Quản lý duyệt lần lượt -> shipper bị trừ nhiều lần cho 1 lần nộp).
  Future<List<PhieuDoiSoatModel>> getPhieuChoDuyet() async {
    try {
      final response = await _apiService.get('/api/DoiSoat/danh-sach-phieu-cho-duyet');
      final list = response as List;
      return list
          .map((e) => PhieuDoiSoatModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}