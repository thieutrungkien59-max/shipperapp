import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../map_tracking/screens/map_delivery_screen.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';

class OrderAcceptScreen extends StatefulWidget {
  final DonHangModel order;

  const OrderAcceptScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderAcceptScreen> createState() => _OrderAcceptScreenState();
}

class _OrderAcceptScreenState extends State<OrderAcceptScreen> {
  // Bộ đếm thời gian 30 giây
  int _timeLeft = 30;
  Timer? _timer;
  bool _isAccepting = false;

  // TODO: Xác nhận lại với backend giá trị trạng thái chính xác khi Shipper nhận đơn
  // (ví dụ: "DaXacNhan", "DangLayHang"...). Đang tạm để "DaXacNhan".
  static const String _trangThaiKhiNhanDon = 'DaXacNhan';

  final Color _primaryRed = const Color(0xFFE51D35);

  late final OrderRepository _orderRepository;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        // Hết giờ: Hủy timer và tự động đóng màn hình, thoát về Home
        _timer?.cancel();
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Đảm bảo hủy timer khi thoát màn hình để tránh lỗi memory leak
    super.dispose();
  }

  Future<void> _handleAcceptOrder() async {
    _timer?.cancel();

    setState(() {
      _isAccepting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      // Gọi API thật để xác nhận nhận đơn
      await _orderRepository.updateOrderStatus(
        widget.order.id,
        maSp,
        _trangThaiKhiNhanDon,
      );

      if (!mounted) return;

      // Nhận đơn thành công: xóa màn hình hiện tại và chuyển sang MapDeliveryScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MapDeliveryScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận đơn: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
        // Đơn vẫn còn hiệu lực trong thời gian còn lại nếu nhận đơn thất bại
        _startTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F0), 
              Color(0xFFFAF8F8),
              Color(0xFFFAF8F8),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Đã giảm bớt chiều cao các SizedBox ở đây để thẻ có thêm không gian
              const SizedBox(height: 16), 
              const Text(
                'ĐƠN HÀNG MỚI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _buildTimerCircle(),
              const SizedBox(height: 24), // Thu gọn khoảng cách từ 40 xuống 24
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildOrderDetailsCard(),
                ),
              ),
              const SizedBox(height: 16), // Đẩy đáy thẻ lên một chút cho thoáng
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CircularProgressIndicator(
            value: _timeLeft / 30.0, // Tính tỷ lệ cho vòng tròn
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_timeLeft',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _primaryRed,
                height: 1.0,
              ),
            ),
            const Text(
              'GIÂY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // Sử dụng Column ở ngoài cùng để chia bố cục
      child: Column(
        children: [
          // 1. PHẦN THÔNG TIN ĐƠN HÀNG (CÓ THỂ CUỘN)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mã đơn hàng',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.id,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildTimeline(),
                  const SizedBox(height: 20),
                  _buildDistanceTimeBox(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildPriceWeightRow(),
                  const SizedBox(height: 16), // Tạo chút khoảng trống ở cuối phần cuộn
                ],
              ),
            ),
          ),
          
          // 2. PHẦN NÚT BẤM VÀ CẢNH BÁO (CỐ ĐỊNH, KHÔNG BỊ CUỘN)
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isAccepting ? null : _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isAccepting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'XÁC NHẬN ĐƠN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(Icons.radio_button_checked, color: _primaryRed, size: 22),
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Địa chỉ lấy hàng', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  const Text('45 Lê Duẩn, Quận 1, TP.HCM', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Color(0xFF28A745), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Địa chỉ giao hàng', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 2),
                  const Text('12 Thảo Điền, Quận 2, TP.HCM', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceTimeBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.route_outlined, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Khoảng cách:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('3.2 km', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Dự kiến:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('15 phút', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceWeightRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Trọng lượng', style: TextStyle(fontSize: 12, color: Colors.black54)),
            SizedBox(height: 4),
            Text('12.5 kg', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Thu hộ COD (VNĐ)', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              '450.000',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}