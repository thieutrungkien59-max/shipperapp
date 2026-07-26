class ApiConstants {
  // Đường dẫn gốc của API (Bỏ đuôi /swagger/index.html đi nhé)
  static const String baseUrl = 'http://192.168.1.249:5262/api';

  // Định nghĩa sẵn các endpoint (ví dụ)
  static const String login = '$baseUrl/auth/login';
  static const String getOrders = '$baseUrl/orders';
  static const String updateOrderStatus = '$baseUrl/orders/status';
}