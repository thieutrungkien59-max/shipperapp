import 'package:flutter/material.dart';
import 'dart:ui';
import '../../orders/screens/order_detail_screen.dart';
import '../../order_proof/screens/camera_proof_screen.dart';
import '../../orders/screens/delivery_failure_screen.dart';

class MapDeliveryScreen extends StatefulWidget {
  const MapDeliveryScreen({Key? key}) : super(key: key);

  @override
  State<MapDeliveryScreen> createState() => _MapDeliveryScreenState();
}

class _MapDeliveryScreenState extends State<MapDeliveryScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  
  bool _isArrived = false;
  bool _isDeliveryPhase = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildMapPlaceholder(),
          Positioned(bottom: 350, right: 16, child: _buildDistanceBadge()),
          Align(alignment: Alignment.bottomCenter, child: _buildBottomSheet(context)),
        ],
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
      title: const Text('LR-VN-10293', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
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
        children: [
          Icon(Icons.directions_car, color: _primaryRed, size: 20),
          const SizedBox(width: 8),
          const Text('2.4 km • 8 phút', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      height: 340, width: double.infinity,
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
                    _isDeliveryPhase ? 'GIAO ĐẾN' : 'NGƯỜI GỬI',
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
                              _isDeliveryPhase ? 'Nguyễn Văn A' : 'Trần Văn B', 
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isDeliveryPhase 
                                  ? '12 Thảo Điền, Phường Thảo Điền, Quận 2, TP.HCM'
                                  : '45 Lê Duẩn, Phường Bến Nghé, Quận 1, TP.HCM', 
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
                          // ĐÃ SỬA LỖI Ở ĐÂY: Lắng nghe tín hiệu từ màn hình Chi tiết trả về
                          onPressed: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderDetailScreen(isDeliveryPhase: _isDeliveryPhase)),
                            );

                            if (success == true) {
                              if (!_isDeliveryPhase) {
                                setState(() {
                                  _isDeliveryPhase = true;
                                  _isArrived = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lấy hàng thành công! Bắt đầu đi giao.')),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              }
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
                                : 'Có thể trễ hạn dự kiến do tình trạng giao thông. Vui lòng liên hệ người gửi nếu cần.',
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
                      onPressed: () async {
                        if (!_isArrived) {
                          setState(() { _isArrived = true; });
                        } else {
                          final success = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CameraProofScreen(isDeliveryPhase: _isDeliveryPhase)),
                          );

                          if (success == true) {
                            if (!_isDeliveryPhase) {
                              setState(() {
                                _isDeliveryPhase = true;
                                _isArrived = false;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Lấy hàng thành công! Bắt đầu đi giao.')),
                                );
                              }
                            } else {
                              if (mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isArrived 
                            ? (_isDeliveryPhase ? 'XÁC NHẬN ĐÃ GIAO HÀNG' : 'XÁC NHẬN ĐÃ LẤY HÀNG') 
                            : 'XÁC NHẬN ĐÃ ĐẾN NƠI',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Chỉ hiện lựa chọn báo cáo thất bại khi đang ở pha giao hàng (không áp dụng lúc lấy hàng)
                  if (_isDeliveryPhase) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final reported = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DeliveryFailureScreen()),
                          );

                          if (reported == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã ghi nhận báo cáo giao thất bại.')),
                            );
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        child: Text(
                          'Không thể giao hàng?',
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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