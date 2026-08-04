import 'package:geolocator/geolocator.dart';

/// Bọc toàn bộ logic xin quyền + đọc GPS thật của thiết bị (qua package geolocator)
/// để các màn hình khác không phải tự lặp lại đoạn xin quyền dài dòng.
class LocationService {
  /// Kiểm tra dịch vụ định vị + xin quyền truy cập vị trí.
  /// Ném Exception với thông báo tiếng Việt rõ ràng nếu bị từ chối, để UI hiển thị trực tiếp.
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Vui lòng bật Dịch vụ vị trí (GPS) trên thiết bị.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Bạn đã từ chối quyền vị trí. Vui lòng cấp quyền để sử dụng bản đồ.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí đã bị chặn vĩnh viễn. Vui lòng vào Cài đặt để bật lại.');
    }
  }

  /// Lấy vị trí hiện tại 1 lần (dùng khi mới mở màn hình bản đồ).
  Future<Position> getCurrentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Lắng nghe vị trí thay đổi LIÊN TỤC, nhưng chỉ bắn sự kiện khi Shipper di chuyển
  /// đủ xa (distanceFilter, đơn vị mét) — đây là điểm TỐI ƯU quan trọng nhất:
  /// - Tiết kiệm pin (không xử lý liên tục dù đứng yên)
  /// - Giảm số lần gọi API cập nhật GPS lên server (không spam mỗi giây)
  /// distanceFilter mặc định 15m: đủ mượt để vẽ lại vị trí trên bản đồ, không quá dày.
  Stream<Position> watchPosition({int distanceFilterMeters = 15}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}