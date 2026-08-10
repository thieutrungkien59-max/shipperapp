import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tiện ích dùng chung để mở app quay số điện thoại (dialer) của thiết bị
/// từ một số điện thoại có trong đơn hàng (SĐT người nhận / người gửi...).
///
/// Lưu ý: hàm chỉ MỞ app quay số để shipper tự bấm gọi, không tự động thực
/// hiện cuộc gọi — nên không cần xin quyền CALL_PHONE nhạy cảm trên Android.
class CallUtils {
  CallUtils._();

  /// Mở app quay số với [phoneNumber]. Hiển thị SnackBar báo lỗi nếu:
  /// - Số điện thoại rỗng/null
  /// - Thiết bị/nền tảng không hỗ trợ mở scheme tel: (vd chạy Web/Desktop trên máy tính)
  static Future<void> call(BuildContext context, String? phoneNumber) async {
    final phone = phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      _showMessage(context, 'Chưa có số điện thoại để gọi.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);

    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        if (context.mounted) {
          _showMessage(context, 'Không thể mở ứng dụng gọi điện trên thiết bị này.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showMessage(context, 'Không thể thực hiện cuộc gọi: $e');
      }
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
