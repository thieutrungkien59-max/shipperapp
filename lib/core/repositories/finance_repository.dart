import '../../models/vi_cod_model.dart';
import '../../services/api_service.dart';
import 'vi_cod_repository.dart';

class FinanceRepository {
  FinanceRepository(this._apiService, {ViCodRepository? legacyFinance})
    : _legacyFinance = legacyFinance ?? ViCodRepository(_apiService);

  final ApiServices _apiService;
  final ViCodRepository _legacyFinance;

  Future<ViCodModel> getWallet(String driverId) async {
    try {
      final response = await _apiService.get('/api/finance/wallet/$driverId');
      if (response is! Map) {
        throw const ApiException('Backend trả dữ liệu ví không hợp lệ.');
      }
      final raw = response['data'] is Map ? response['data'] : response;
      return ViCodModel.fromJson(Map<String, dynamic>.from(raw as Map));
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _legacyFinance.getViCodByShipper(driverId);
    }
  }
}
