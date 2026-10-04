import '../../models/don_hang_model.dart';
import '../../services/api_service.dart';
import 'order_repository.dart';

class DeliveryRepository {
  DeliveryRepository(this._apiService, {OrderRepository? legacyOrders})
    : _legacyOrders = legacyOrders ?? OrderRepository(_apiService);

  final ApiServices _apiService;
  final OrderRepository _legacyOrders;

  Future<DonHangModel> getDelivery(String orderId) async {
    try {
      final response = await _apiService.get('/api/delivery/$orderId');
      return DonHangModel.fromJson(_unwrapMap(response));
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _legacyOrders.getOrderDetail(orderId);
    }
  }

  Future<List<DonHangModel>> getDriverJobs(String driverId) async {
    try {
      final response = await _apiService.get('/api/delivery/driver/$driverId');
      return _parseList(response);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _legacyOrders.getOrdersByShipper(driverId);
    }
  }

  Future<void> completeDelivery({
    required String deliveryId,
    required String orderId,
    required String driverId,
    String? proofReference,
    String? otp,
  }) async {
    try {
      await _apiService.post('/api/delivery/$deliveryId/complete', {
        'orderId': orderId,
        'driverId': driverId,
        'proofReference': ?proofReference,
        'otp': ?otp,
      });
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      await _legacyOrders.updateOrderStatus(orderId, driverId, 'DaGiao');
    }
  }

  List<DonHangModel> _parseList(dynamic response) {
    final raw = response is List
        ? response
        : response is Map && response['data'] is List
        ? response['data'] as List
        : response is Map && response['\$values'] is List
        ? response['\$values'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map((item) => DonHangModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _unwrapMap(dynamic response) {
    if (response is! Map) {
      throw const ApiException('Backend trả dữ liệu delivery không hợp lệ.');
    }
    final raw = response['data'] is Map ? response['data'] : response;
    return Map<String, dynamic>.from(raw as Map);
  }
}
