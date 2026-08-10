import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Kết quả mô phỏng đường đi từ [from] đến [to]: danh sách điểm tạo thành
/// polyline và tổng quãng đường ước tính (km).
///
/// LƯU Ý: đây là dữ liệu MÔ PHỎNG — KHÔNG phải toạ độ/khoảng cách thật,
/// vì hiện tại `diaChiLay` / `diaChiGiao` trong đơn hàng chỉ là chuỗi text
/// (vd "Q7", "Q6"), backend chưa trả toạ độ lat/lng thật. Khi backend có
/// API geocode hoặc trả sẵn toạ độ, cần thay thế toàn bộ class này bằng
/// dữ liệu thật (và nên gọi OSRM/routing service thật để có đường đi chính xác).
class SimulatedRoute {
  final LatLng from;
  final LatLng to;
  final List<LatLng> routePoints;
  final double distanceKm;
  // Khi có dữ liệu THẬT từ backend (OSRM), dùng thời gian thật thay vì ước lượng
  final int? etaMinutesOverride;

  const SimulatedRoute({
    required this.from,
    required this.to,
    required this.routePoints,
    required this.distanceKm,
    this.etaMinutesOverride,
  });

  // Thời gian ước tính (phút): dùng etaMinutesOverride nếu có (dữ liệu thật),
  // ngược lại tự ước lượng theo tốc độ trung bình xe máy trong nội thành ~25km/h
  int get etaMinutes => etaMinutesOverride ?? (distanceKm / 25 * 60).round().clamp(1, 999);
}

/// Toạ độ CỐ ĐỊNH của điểm lấy hàng và điểm giao hàng cho 1 đơn hàng.
/// 2 điểm này không đổi trong suốt vòng đời đơn hàng (vì là địa chỉ thật),
/// khác với đường đi (route) sẽ thay đổi theo vị trí hiện tại của shipper.
class FixedRoutePoints {
  final LatLng pickupPoint;
  final LatLng dropoffPoint;

  const FixedRoutePoints({required this.pickupPoint, required this.dropoffPoint});
}

class RouteSimulator {
  RouteSimulator._();

  // Toạ độ trung tâm TP.HCM — dùng làm điểm neo mặc định để sinh vị trí lấy/giao hàng
  static const LatLng _defaultAnchor = LatLng(10.7769, 106.7009);
  static const Distance _distanceCalc = Distance();

  /// Sinh toạ độ CỐ ĐỊNH cho điểm lấy hàng & điểm giao hàng dựa theo [seedText]
  /// (thường là mã đơn + địa chỉ) — cùng 1 đơn hàng luôn ra cùng 2 điểm này,
  /// không phụ thuộc vị trí GPS hiện tại của shipper.
  static FixedRoutePoints resolveFixedPoints(String seedText) {
    final rnd = Random(seedText.hashCode);

    // Điểm lấy hàng: lệch khỏi trung tâm mặc định 1km - 4km theo hướng ngẫu nhiên
    final pickupDistanceKm = 1.0 + rnd.nextDouble() * 3.0;
    final pickupBearing = rnd.nextDouble() * 360;
    final pickupPoint = _offset(_defaultAnchor, pickupDistanceKm, pickupBearing);

    // Điểm giao hàng: lệch tiếp từ điểm lấy hàng 1.5km - 6km theo hướng khác hẳn
    final dropoffDistanceKm = 1.5 + rnd.nextDouble() * 4.5;
    final dropoffBearing = (pickupBearing + 60 + rnd.nextDouble() * 240) % 360;
    final dropoffPoint = _offset(pickupPoint, dropoffDistanceKm, dropoffBearing);

    return FixedRoutePoints(pickupPoint: pickupPoint, dropoffPoint: dropoffPoint);
  }

  /// Vẽ đường đi MÔ PHỎNG từ [from] (thường là GPS hiện tại của shipper) đến [to]
  /// (điểm lấy hàng ở pha 1, hoặc điểm giao hàng ở pha 2). [seedText] (tuỳ chọn)
  /// giúp đường đi ổn định thay vì đổi hình dạng lộn xộn mỗi lần gọi lại.
  static SimulatedRoute buildPath({required LatLng from, required LatLng to, String? seedText}) {
    final seed = seedText ?? '${from.latitude}_${from.longitude}_${to.latitude}_${to.longitude}';
    final rnd = Random(seed.hashCode);

    final routePoints = _buildJitteredPath(from, to, rnd);
    final distanceKm = _pathLength(routePoints);

    return SimulatedRoute(from: from, to: to, routePoints: routePoints, distanceKm: distanceKm);
  }

  static List<LatLng> _buildJitteredPath(LatLng start, LatLng end, Random rnd) {
    const int segments = 6;
    final List<LatLng> points = [start];

    final double totalDistanceKm = _distanceCalc.distance(start, end) / 1000;
    // Biên độ lệch tỉ lệ theo quãng đường, giữ vừa phải để không vẽ loạn
    final double jitterKm = (totalDistanceKm * 0.06).clamp(0.03, 0.35);
    final double baseBearing = _distanceCalc.bearing(start, end);

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final midPoint = LatLng(
        start.latitude + (end.latitude - start.latitude) * t,
        start.longitude + (end.longitude - start.longitude) * t,
      );

      // Lệch vuông góc với đường nối 2 điểm, đổi hướng xen kẽ để tạo hình zíc-zắc nhẹ
      final perpendicularBearing = baseBearing + (i.isEven ? 90 : -90);
      final jitterDistanceKm = jitterKm * rnd.nextDouble();
      points.add(_offset(midPoint, jitterDistanceKm, perpendicularBearing));
    }

    points.add(end);
    return points;
  }

  static double _pathLength(List<LatLng> points) {
    double totalMeters = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalMeters += _distanceCalc.distance(points[i], points[i + 1]);
    }
    return totalMeters / 1000;
  }

  // Dịch chuyển 1 điểm toạ độ theo khoảng cách (km) và hướng (độ, 0 = Bắc)
  static LatLng _offset(LatLng point, double distanceKm, double bearingDeg) {
    return _distanceCalc.offset(point, distanceKm * 1000, bearingDeg);
  }
}