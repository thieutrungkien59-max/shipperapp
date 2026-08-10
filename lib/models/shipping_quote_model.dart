import 'package:latlong2/latlong.dart';

/// Kết quả tính tuyến đường bộ THẬT + phí vận chuyển, trả về từ
/// POST /api/DonHang/tinh-phi-van-chuyen (backend gọi OSRM thật).
/// Cấu trúc y hệt bên app người dùng để 2 app hiển thị nhất quán.
class ShippingQuoteModel {
  const ShippingQuoteModel({
    required this.distanceKm,
    required this.durationMinutes,
    required this.baseFee,
    required this.feePerKm,
    required this.isPeakHour,
    required this.peakMultiplier,
    required this.shippingFee,
    required this.routePoints,
  });

  final double distanceKm;
  final int durationMinutes;
  final double baseFee;
  final double feePerKm;
  final bool isPeakHour;
  final double peakMultiplier;
  final double shippingFee;
  final List<LatLng> routePoints;

  factory ShippingQuoteModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['routePoints'];

    final points = <LatLng>[];

    if (rawPoints is List) {
      for (final item in rawPoints) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final lat = _asDouble(map['latitude'] ?? map['Latitude']);
        final lng = _asDouble(map['longitude'] ?? map['Longitude']);

        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }

    return ShippingQuoteModel(
      distanceKm: _asDouble(json['distanceKm']) ?? 0,
      durationMinutes: _asInt(json['durationMinutes']) ?? 0,
      baseFee: _asDouble(json['baseFee']) ?? 0,
      feePerKm: _asDouble(json['feePerKm']) ?? 0,
      isPeakHour: _asBool(json['isPeakHour']),
      peakMultiplier: _asDouble(json['peakMultiplier']) ?? 1,
      shippingFee: _asDouble(json['shippingFee']) ?? 0,
      routePoints: points,
    );
  }
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}