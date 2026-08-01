import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../map_tracking/screens/map_delivery_screen.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';

class OrderAcceptScreen extends StatefulWidget {
  final String maDh;

  const OrderAcceptScreen({Key? key, required this.maDh}) : super(key: key);

  @override
  State<OrderAcceptScreen> createState() => _OrderAcceptScreenState();
}

class _OrderAcceptScreenState extends State<OrderAcceptScreen> {
  // Bộ đếm thời gian 30 giây (chỉ chạy sau khi đã tải xong dữ liệu)
  int _timeLeft = 30;
  Timer? _timer;
  bool _isAccepting = false;

  // Trạng thái tải dữ liệu chi tiết đơn hàng + thông tin xe của Shipper
  bool _isLoading = true;
  String? _loadError;
  DonHangModel? _order;
  double _taiTrongXe = 0;

  // TODO: Xác nhận lại với backend giá trị trạng thái chính xác khi Shipper nhận đơn
  // (ví dụ: "DaXacNhan", "DangLayHang"...). Đang tạm để "DaXacNhan".
  static const String _trangThaiKhiNhanDon = 'DaXacNhan';

  final Color _primaryRed = const Color(0xFFE51D35);

  late final OrderRepository _orderRepository;
  late final ApiServices _apiService;

  // Đơn hàng có vượt tải trọng tối đa xe của Shipper hay không
  bool get _isOverWeight => _order != null && _order!.khoiLuong > _taiTrongXe && _taiTrongXe > 0;

  @override
  void initState() {
    super.initState();
    _apiService = ApiServices();
    _orderRepository = OrderRepository(_apiService);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maTk = prefs.getString('maTk');

      // Gọi song song: chi tiết đơn hàng + hồ sơ Shipper (để lấy tải trọng tối đa xe)
      final results = await Future.wait([
        _orderRepository.getOrderDetail(widget.maDh),
        if (maTk != null && maTk.isNotEmpty) _apiService.get('/api/Auth/profile/$maTk') else Future.value(null),
      ]);

      final order = results[0] as DonHangModel;
      final profileResponse = results[1];

      double taiTrong = 0;
      if (profileResponse != null && profileResponse is Map) {
        final chiTiet = profileResponse['chiTiet'] ?? {};
        final raw = chiTiet['taiTrongToiDa'];
        taiTrong = (raw is num) ? raw.toDouble() : double.tryParse('$raw') ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _order = order;
        _taiTrongXe = taiTrong;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
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
    if (_order == null || _isOverWeight) return;

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
        _order!.maDh,
        maSp,
        _trangThaiKhiNhanDon,
      );

      if (!mounted) return;

      // Nhận đơn thành công: xóa màn hình hiện tại và chuyển sang MapDeliveryScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapDeliveryScreen(maDh: _order!.maDh),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? _buildErrorState()
                  : Column(
                      children: [
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
                        const SizedBox(height: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildOrderDetailsCard(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              'Không tải được chi tiết đơn hàng:\n$_loadError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
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
    final order = _order!;

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
                    order.maDh,
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
                  _buildTimeline(order),
                  const SizedBox(height: 20),
                  _buildReceiverBox(order),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildPriceWeightRow(order),
                  if (_isOverWeight) ...[
                    const SizedBox(height: 14),
                    _buildOverWeightWarning(order),
                  ],
                  const SizedBox(height: 16),
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
              onPressed: (_isAccepting || _isOverWeight) ? null : _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOverWeight ? Colors.grey.shade400 : _primaryRed,
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
                  : Text(
                      _isOverWeight ? 'VƯỢT TẢI TRỌNG XE' : 'XÁC NHẬN ĐƠN',
                      style: const TextStyle(
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

  Widget _buildTimeline(DonHangModel order) {
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
                  Text(order.diaChiLay, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                  Text(order.diaChiGiao, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiverBox(DonHangModel order) {
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
                Icon(Icons.person_outline, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Người nhận:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(
                        order.tenNguoiNhan,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_outlined, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SĐT:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(order.sdtNguoiNhan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceWeightRow(DonHangModel order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Khối lượng', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              '${order.khoiLuong} kg',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _isOverWeight ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Thu hộ COD (VNĐ)', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              order.tienCod.toStringAsFixed(0),
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

  Widget _buildOverWeightWarning(DonHangModel order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Khối lượng đơn (${order.khoiLuong} kg) vượt quá tải trọng tối đa xe của bạn '
              '(${_taiTrongXe.toStringAsFixed(0)} kg). Bạn không thể nhận đơn này.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}