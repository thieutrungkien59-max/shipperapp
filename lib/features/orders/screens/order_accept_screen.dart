import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/repositories/order_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../map_tracking/screens/map_delivery_screen.dart';

class OrderAcceptScreen extends StatefulWidget {
  final String maDh;

  // Hint từ màn trước để giữ tương thích.
  //
  // HOTFIX D1:
  // OrderAcceptScreen KHÔNG dùng flag này làm nguồn sự thật nữa.
  // Sau khi mở màn hình, backend sẽ được hỏi lại để xác định:
  // - assignment của chính Shipper => assigned mode 60s
  // - đơn vẫn ở pool ChoXacNhan    => self-accept mode 30s
  final bool isSelfAccept;

  const OrderAcceptScreen({
    Key? key,
    required this.maDh,
    this.isSelfAccept = false,
  }) : super(key: key);

  @override
  State<OrderAcceptScreen> createState() => _OrderAcceptScreenState();
}

class _OrderAcceptScreenState extends State<OrderAcceptScreen> {
  // Countdown chỉ bắt đầu SAU KHI backend xác định mode thật của đơn.
  int _timeLeft = 0;

  // false = assignment của chính Shipper (60s)
  // true  = đơn đang ở pool ChoXacNhan (30s)
  bool _isSelfAcceptMode = false;

  // Chỉ true khi đơn hiện vẫn thực sự actionable với Shipper này.
  bool _isOrderActionable = false;

  int get _countdownTotalSeconds => _isSelfAcceptMode ? 30 : 60;
  Timer? _timer;
  bool _isAccepting = false;
  bool _isReleasing = false;

  // Trạng thái tải dữ liệu chi tiết đơn hàng + thông tin xe của Shipper
  bool _isLoading = true;
  String? _loadError;
  DonHangModel? _order;
  double _taiTrongXe = 0;

  final Color _primaryRed = const Color(0xFFE51D35);

  late final OrderRepository _orderRepository;
  late final ApiServices _apiService;

  // Đơn hàng có vượt tải trọng tối đa xe của Shipper hay không
  bool get _isOverWeight =>
      _order != null && _order!.khoiLuong > _taiTrongXe && _taiTrongXe > 0;

  @override
  void initState() {
    super.initState();

    _apiService = ApiServices();
    _orderRepository = OrderRepository(_apiService);
    _loadData();
  }

  Future<void> _loadData() async {
    _timer?.cancel();

    setState(() {
      _isLoading = true;
      _loadError = null;
      _isOrderActionable = false;
      _timeLeft = 0;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maTk = prefs.getString('maTk');
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      // HOTFIX D1 - BACKEND LÀ NGUỒN SỰ THẬT.
      //
      // Không tin widget.isSelfAccept vì từ lúc Home mở màn hình tới đây,
      // Auto Dispatch có thể vừa:
      // - assign đơn;
      // - nhận reject;
      // - trả về pool;
      // - retry cho Shipper khác.
      //
      // Vì vậy tải đồng thời:
      // 1. chi tiết đơn;
      // 2. profile;
      // 3. assignment hiện tại CỦA CHÍNH Shipper;
      // 4. pool ChoXacNhan hiện tại.
      final results = await Future.wait([
        _orderRepository.getOrderDetail(widget.maDh),
        if (AppConfig.demoMode)
          Future.value({
            'chiTiet': {'taiTrongToiDa': 20},
          })
        else if (maTk != null && maTk.isNotEmpty)
          _apiService.get('/api/Auth/profile/$maTk')
        else
          Future.value(null),
        _orderRepository.getAssignedOrdersWaitingConfirmation(maSp),
        _orderRepository.getOrdersAvailableToAccept(),
      ]);

      final order = results[0] as DonHangModel;
      final profileResponse = results[1];
      final assignedOrders = results[2] as List<DonHangModel>;
      final availablePool = results[3] as List<DonHangModel>;

      final isAssignedToCurrentShipper = assignedOrders.any(
        (item) => item.maDh == widget.maDh,
      );

      final isStillAvailableInPool = availablePool.any(
        (item) => item.maDh == widget.maDh,
      );

      // Assignment của chính Shipper được ưu tiên.
      //
      // Nếu vì timing mà endpoint pool và assigned overlap trong một khoảnh
      // khắc cực ngắn, ta vẫn dùng assigned mode để tránh self-claim sai.
      final bool resolvedSelfAcceptMode;
      if (isAssignedToCurrentShipper) {
        resolvedSelfAcceptMode = false;
      } else if (isStillAvailableInPool) {
        resolvedSelfAcceptMode = true;
      } else {
        // Đơn không còn thuộc assignment của shipper hiện tại
        // và cũng không còn ở pool => dữ liệu Home/màn trước đã stale.
        if (!mounted) return;

        setState(() {
          _order = order;
          _isLoading = false;
          _isOrderActionable = false;
          _loadError =
              'Đơn hàng đã thay đổi trạng thái hoặc đã được Shipper khác tiếp nhận. '
              'Vui lòng quay lại Home để làm mới danh sách.';
        });
        return;
      }

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
        _isSelfAcceptMode = resolvedSelfAcceptMode;
        _isOrderActionable = true;
        _timeLeft = resolvedSelfAcceptMode ? 30 : 60;
        _isLoading = false;
      });

      debugPrint(
        '[ORDER_ACCEPT_SYNC] ${widget.maDh} '
        'mode=${resolvedSelfAcceptMode ? "SELF_ACCEPT" : "ASSIGNED"} '
        'status=${order.trangThai}',
      );

      _startTimer();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isOrderActionable = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (!_isOrderActionable || _timeLeft <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _handleRejectOrder(
          reason: 'Hết $_countdownTotalSeconds giây không phản hồi',
          showMessage: false,
          isTimeout: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Đảm bảo hủy timer khi thoát màn hình để tránh lỗi memory leak
    super.dispose();
  }

  Future<void> _handleAcceptOrder() async {
    if (_order == null || _isOverWeight || !_isOrderActionable) return;

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

      if (_isSelfAcceptMode) {
        // Backend vừa xác nhận đơn hiện vẫn ở pool ChoXacNhan.
        // Backend sẽ atomically claim đơn, gán MaSp và chuyển DaXacNhan.
        await _orderRepository.selfAcceptAvailableOrder(
          maDonHang: _order!.maDh,
          maShipper: maSp,
        );
      } else {
        // Flow cũ: đơn đã được Admin chỉ định cho chính Shipper này.
        await _orderRepository.respondToAssignedOrder(
          maDonHang: _order!.maDh,
          maShipper: maSp,
          chapNhan: true,
        );
      }

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
            content: Text(
              'Lỗi nhận đơn: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Có thể trạng thái vừa đổi do Auto Dispatch/race condition.
        // Không giữ màn hình trong mode cũ; đồng bộ lại backend ngay.
        await _loadData();
      }
    }
  }

  Future<void> _handleRejectOrder({
    String reason = 'Shipper từ chối đơn',
    bool showMessage = true,
    bool isTimeout = false,
  }) async {
    if (_order == null || _isReleasing || !_isOrderActionable) return;

    _timer?.cancel();

    setState(() {
      _isReleasing = true;
    });

    try {
      // Với đơn tự chọn từ pool, Shipper CHƯA sở hữu đơn.
      // Từ chối/timeout chỉ đóng màn hình; không được gọi API trả đơn,
      // vì đơn vẫn đang ChoXacNhan và MaSp vẫn null.
      if (_isSelfAcceptMode) {
        if (!mounted) return;

        Navigator.pop(context, isTimeout ? 'self_timeout' : 'self_cancelled');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper.');
      }

      await _orderRepository.respondToAssignedOrder(
        maDonHang: _order!.maDh,
        maShipper: maSp,
        chapNhan: false,
        lyDo: reason,
      );

      if (!mounted) return;

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối đơn. Đơn được trả về điều phối.'),
          ),
        );
      }

      Navigator.pop(context, isTimeout ? 'timeout' : 'rejected');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isReleasing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trạng thái đơn vừa thay đổi: '
            '${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );

      // Không để user mắc kẹt ở màn 60s/30s đã stale.
      // Tải lại backend để chuyển mode hoặc hiện trạng thái không còn hợp lệ.
      await _loadData();
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
            colors: [Color(0xFFFFF0F0), Color(0xFFFAF8F8), Color(0xFFFAF8F8)],
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
                    Text(
                      _isSelfAcceptMode ? 'ĐƠN CHỜ NHẬN' : 'ĐƠN HÀNG MỚI',
                      style: const TextStyle(
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
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
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
            value: _timeLeft / _countdownTotalSeconds,
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
              onPressed:
                  (_isAccepting ||
                      _isReleasing ||
                      _isOverWeight ||
                      !_isOrderActionable)
                  ? null
                  : _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOverWeight
                    ? Colors.grey.shade400
                    : _primaryRed,
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
                      _isOverWeight
                          ? 'VƯỢT TẢI TRỌNG XE'
                          : _isSelfAcceptMode
                          ? 'NHẬN ĐƠN'
                          : 'XÁC NHẬN ĐƠN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: (_isAccepting || _isReleasing || !_isOrderActionable)
                ? null
                : () => _handleRejectOrder(),
            child: _isReleasing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isSelfAcceptMode ? 'BỎ QUA ĐƠN' : 'TỪ CHỐI ĐƠN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
          ),
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
                  const Text(
                    'Địa chỉ lấy hàng',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.diaChiLay,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
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
                  const Text(
                    'Địa chỉ giao hàng',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.diaChiGiao,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
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
                Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Người nhận:',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        order.tenNguoiNhan,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
                Icon(
                  Icons.phone_outlined,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SĐT:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      order.sdtNguoiNhan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            const Text(
              'Khối lượng',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
            const Text(
              'Thu hộ COD (VNĐ)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 20,
          ),
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
