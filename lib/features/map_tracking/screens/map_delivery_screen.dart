import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../orders/screens/order_detail_screen.dart';
import '../../order_proof/screens/camera_proof_screen.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';

class MapDeliveryScreen extends StatefulWidget {
  final String maDh;

  const MapDeliveryScreen({Key? key, required this.maDh}) : super(key: key);

  @override
  State<MapDeliveryScreen> createState() => _MapDeliveryScreenState();
}

class _MapDeliveryScreenState extends State<MapDeliveryScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);

  bool _isArrived = false;
  bool _isDeliveryPhase = false; // false = đang trong pha "đi lấy hàng" (DaXacNhan), true = đang giao (DangGiao)

  bool _isLoading = true;
  String? _loadError;
  DonHangModel? _order;
  bool _isCancelling = false;
  bool _isUpdatingStatus = false;

  late final OrderRepository _orderRepository;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final order = await _orderRepository.getOrderDetail(widget.maDh);
      if (!mounted) return;
      setState(() {
        _order = order;
        // Nếu mở lại màn này khi đơn đã ở trạng thái DangGiao (vd. mở từ tab Orders), vào thẳng pha giao hàng
        _isDeliveryPhase = order.trangThai == 'DangGiao';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Gọi API đổi trạng thái đơn (DangGiao khi lấy hàng xong, DaGiao khi giao xong, DaHuy khi huỷ)
  Future<bool> _updateOrderStatus(String trangThaiMoi, {String ghiChu = ''}) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');
      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }
      await _orderRepository.updateOrderStatus(widget.maDh, maSp, trangThaiMoi, ghiChu: ghiChu);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật đơn: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  // Chỉ được huỷ khi CHƯA lấy hàng thành công (đơn còn ở pha DaXacNhan)
  Future<void> _handleCancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Huỷ đơn hàng?'),
        content: const Text('Bạn chắc chắn muốn huỷ đơn này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Huỷ đơn', style: TextStyle(color: _primaryRed)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final success = await _updateOrderStatus('DaHuy', ghiChu: 'Shipper huỷ đơn trước khi lấy hàng');
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // Được gọi sau khi Camera xác nhận đủ minh chứng (chụp ảnh lấy hàng / giao hàng)
  Future<void> _handleProofSuccess() async {
    if (!_isDeliveryPhase) {
      // Vừa lấy hàng xong -> chuyển đơn sang DangGiao
      final success = await _updateOrderStatus('DangGiao', ghiChu: 'Shipper đã lấy hàng');
      if (!mounted || !success) return;
      setState(() {
        _isDeliveryPhase = true;
        _isArrived = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lấy hàng thành công! Bắt đầu đi giao.')),
      );
    } else {
      // Vừa giao hàng xong -> chuyển đơn sang DaGiao rồi thoát về Home
      final success = await _updateOrderStatus('DaGiao', ghiChu: 'Shipper đã giao hàng thành công');
      if (!mounted || !success) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : Stack(
                  children: [
                    _buildMapPlaceholder(),
                    Positioned(bottom: 350, right: 16, child: _buildDistanceBadge()),
                    Align(alignment: Alignment.bottomCenter, child: _buildBottomSheet(context)),
                  ],
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
            Text('Không tải được đơn hàng:\n$_loadError', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrder,
              style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.maDh, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _primaryRed, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  _isDeliveryPhase ? 'ĐANG GIAO' : 'LẤY HÀNG',
                  style: TextStyle(color: _primaryRed, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity, height: double.infinity,
      color: const Color(0xFFEAEAEA),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.map, size: 100, color: Colors.grey.shade400),
          CustomPaint(size: const Size(double.infinity, double.infinity), painter: RoutePainter(_primaryRed)),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.directions_car, color: Colors.black54, size: 20),
          SizedBox(width: 8),
          // TODO: API hiện chưa trả về khoảng cách/thời gian dự kiến thực tế
          Text('Chưa có dữ liệu quãng đường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    final order = _order!;
    // Chỉ được phép huỷ khi CHƯA lấy hàng thành công (còn ở pha DaXacNhan)
    final bool canCancel = !_isDeliveryPhase;

    return Container(
      height: canCancel ? 400 : 340, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isDeliveryPhase ? 'GIAO ĐẾN' : 'ĐỊA CHỈ LẤY HÀNG',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDeliveryPhase ? order.tenNguoiNhan : 'Điểm lấy hàng',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDeliveryPhase ? order.diaChiGiao : order.diaChiLay,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFFF9EFEB), shape: BoxShape.circle),
                        child: const Icon(Icons.phone, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.navigation_outlined, color: Colors.black87, size: 18),
                          label: const Text('Chỉ đường', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(isDeliveryPhase: _isDeliveryPhase, order: order),
                              ),
                            );
                            if (success == true) {
                              await _handleProofSuccess();
                            }
                          },
                          icon: const Icon(Icons.receipt_long_outlined, color: Colors.black87, size: 18),
                          label: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3E9), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.access_time, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isDeliveryPhase
                                ? 'Có thể trễ hạn dự kiến do tình trạng giao thông. Vui lòng liên hệ người nhận nếu cần.'
                                : 'Đơn hàng chỉ có thể huỷ trước khi bạn xác nhận đã lấy hàng.',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NÚT XÁC NHẬN CHÍNH
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isUpdatingStatus
                          ? null
                          : () async {
                              if (!_isArrived) {
                                setState(() { _isArrived = true; });
                              } else {
                                final success = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CameraProofScreen(isDeliveryPhase: _isDeliveryPhase, maDh: widget.maDh),
                                  ),
                                );
                                if (success == true) {
                                  await _handleProofSuccess();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isUpdatingStatus
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isArrived
                                  ? (_isDeliveryPhase ? 'XÁC NHẬN ĐÃ GIAO HÀNG' : 'XÁC NHẬN ĐÃ LẤY HÀNG')
                                  : 'XÁC NHẬN ĐÃ ĐẾN NƠI',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                            ),
                    ),
                  ),

                  // NÚT HUỶ ĐƠN: chỉ hiện khi chưa xác nhận lấy hàng thành công
                  if (canCancel) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isCancelling ? null : _handleCancelOrder,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryRed),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isCancelling
                            ? SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _primaryRed),
                              )
                            : Text('Huỷ đơn hàng', style: TextStyle(color: _primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  final Color color;
  RoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color.withOpacity(0.6)..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    var path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.7, size.height * 0.3);

    const double dashWidth = 15, dashSpace = 10;
    double distance = 0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}