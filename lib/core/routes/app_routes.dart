import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';

/// Quản lý tên route và cách tạo route cho toàn app.
/// Khi có màn hình mới, chỉ cần thêm:
///   1. Một hằng số tên route ở dưới
///   2. Một case trong generateRoute()
/// KHÔNG sửa main.dart nữa — tránh xung đột Git khi nhiều người cùng thêm màn hình.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String orders = '/orders';

  // TODO: thêm khi các màn hình dưới đây được code xong
  // static const String otp = '/otp';
  // static const String register = '/register';
  // static const String mapDelivery = '/map-delivery';
  // static const String cameraProof = '/camera-proof';
  // static const String wallet = '/wallet';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrderListScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy route: ${settings.name}'),
            ),
          ),
        );
    }
  }
}