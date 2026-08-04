import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../orders/screens/order_detail_screen.dart';
import '../../orders/screens/delivery_failure_screen.dart';
import '../../order_proof/screens/camera_proof_screen.dart';
import 'full_map_screen.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../services/location_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/shipper_repository.dart';

// Bật quyền cho chuột máy tính có thể vuốt (drag) như ngón tay
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class MapDeliveryScreen extends StatefulWidget {
  final String maDh;

  const MapDeliveryScreen({Key? key, required this.maDh}) : super(key: key);

  @override
  State<MapDeliveryScreen> createState() => _MapDeliveryScreenState();
}

class _MapDeliveryScreenState extends State<MapDeliveryScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);

  bool _isArrived = false;
  bool _isDeliveryPhase = false; 

  bool _isLoading = true;
  String? _loadError;
  DonHangModel? _order;
  bool _isCancelling = false;
  bool _isUpdatingStatus = false;

  late final OrderRepository _orderRepository;
  late final ShipperRepository _shipperRepository;
  late final LocationService _locationService;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentLatLng;
  String? _gpsError;

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  // Cho phép hạ mức thấp nhất xuống 0.06 (6%) để giấu thẻ trắng, hiện full bản đồ
  static const List<double> _sheetSnapSizes = [0.06, 0.50, 0.85];
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.50);

  DateTime? _lastGpsSentAt;
  static const Duration _minGpsSendInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _shipperRepository = ShipperRepository(ApiServices());
    _locationService = LocationService();
    
    _sheetController.addListener(() {
      if (_sheetController.isAttached) {
        _sheetExtent.value = _sheetController.size;
      }
    });

    _loadOrder();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      final initialPosition = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);
      });
      _mapController.move(_currentLatLng!, 16);
      _sendGpsUpdate(initialPosition, force: true);

      _positionSubscription = _locationService.watchPosition().listen((position) {
        if (!mounted) return;
        final newLatLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentLatLng = newLatLng);
        _mapController.move(newLatLng, _mapController.camera.zoom);
        _sendGpsUpdate(position);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _gpsError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _sendGpsUpdate(Position position, {bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastGpsSentAt != null && now.difference(_lastGpsSentAt!) < _minGpsSendInterval) {
      return; 
    }
    _lastGpsSentAt = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');
      if (maSp == null || maSp.isEmpty) return;

      await _shipperRepository.updateGpsLocation(
        maShipper: maSp,
        kinhDo: position.longitude,
        viDo: position.latitude,
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật GPS: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _sheetExtent.dispose();
    super.dispose();
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

  Future<void> _handleReportFailure() async {
    final updatedOrder = await Navigator.push<DonHangModel>(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryFailureScreen(
          maDonHang: widget.maDh,
          soLanThatBaiHienTai: _order?.soLanGiaoThatBai ?? 0,
        ),
      ),
    );

    if (updatedOrder == null || !mounted) return;

    if (updatedOrder.trangThai == 'DangGiao') {
      setState(() {
        _order = updatedOrder;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ghi nhận thất bại lần ${updatedOrder.soLanGiaoThatBai}. Tiếp tục giao hàng.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đơn đã được cập nhật trạng thái: "${_statusLabel(updatedOrder.trangThai)}".')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _handleProofSuccess() async {
    if (!_isDeliveryPhase) {
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
      final success = await _updateOrderStatus('DaGiao', ghiChu: 'Shipper đã giao hàng thành công');
      if (!mounted || !success) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _statusLabel(String trangThai) {
    switch (trangThai) {
      case 'ChoXacNhan':
        return 'Chờ xác nhận';
      case 'DaXacNhan':
        return 'Đã xác nhận';
      case 'DangGiao':
        return 'Đang giao';
      case 'DaGiao':
        return 'Đã giao';
      case 'GiaoThatBai':
        return 'Giao thất bại';
      case 'DaHuy':
        return 'Đã huỷ';
      case 'HuyTraHang':
        return 'Huỷ trả hàng';
      default:
        return trangThai;
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
                    
                    ValueListenableBuilder<double>(
                      valueListenable: _sheetExtent,
                      builder: (context, extent, child) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        // Giới hạn cappedExtent ở mức 0.55 để các nút không bao giờ bị đẩy lọt ra khỏi màn hình trên cùng
                        final cappedExtent = extent > 0.55 ? 0.55 : extent;
                        final bottomPosition = (screenHeight * cappedExtent) + 16;
                        
                        return Positioned(
                          bottom: bottomPosition,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFullMapButton(),
                              const SizedBox(height: 12),
                              _buildRecenterButton(),
                              const SizedBox(height: 12),
                              _buildDistanceBadge(),
                            ],
                          ),
                        );
                      },
                    ),

                    _buildDraggableBottomSheet(context),
                  ],
                ),
    );
  }

  void _recenterToCurrentLocation() {
    if (_currentLatLng == null) return;
    _mapController.move(_currentLatLng!, _mapController.camera.zoom < 15 ? 16 : _mapController.camera.zoom);
  }

  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: _recenterToCurrentLocation,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.my_location, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  Widget _buildFullMapButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () {
          if (_order == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullMapScreen(order: _order!, isDeliveryPhase: _isDeliveryPhase),
            ),
          );
        },
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.fullscreen, color: Colors.black87, size: 22),
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet(BuildContext context) {
    return ScrollConfiguration(
      behavior: _MouseDragScrollBehavior(),
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.50, // Mặc định hiển thị vừa đủ thông tin ở mức 50%
        minChildSize: 0.06,     // Cho phép vuốt mất luôn thẻ trắng (chỉ chừa thanh xám 6%)
        maxChildSize: 0.85,
        snap: true,
        snapSizes: _sheetSnapSizes,
        builder: (context, scrollController) {
          return _buildBottomSheet(context, scrollController);
        },
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
    if (_currentLatLng == null && _gpsError == null) {
      return Container(
        width: double.infinity, height: double.infinity,
        color: const Color(0xFFEAEAEA),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_gpsError != null && _currentLatLng == null) {
      return Container(
        width: double.infinity, height: double.infinity,
        color: const Color(0xFFEAEAEA),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(_gpsError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _gpsError = null);
                    _startLocationTracking();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
                  child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng!,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.logiroute.shipperapp',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLatLng!,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: _primaryRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                ),
                child: const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
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
          Text('Chưa có dữ liệu quãng đường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, ScrollController scrollController) {
    final order = _order!;
    final bool canCancel = !_isDeliveryPhase;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          // === KHU VỰC TAY CẦM VUỐT CHÍNH THỨC CỦA FLUTTER ===
          SizedBox(
            height: 36, // Vùng nhận thao tác vuốt
            child: ListView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(), // Ép nhận thao tác vuốt trượt thẻ
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 36,
                  color: Colors.transparent, // Trong suốt để không bị lọt thao tác
                  child: Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300, 
                        borderRadius: BorderRadius.circular(4)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === KHU VỰC NỘI DUNG TRƯỢT ĐỘC LẬP BÊN DƯỚI ===
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              physics: const BouncingScrollPhysics(),
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
                        label: const Text('Chi tiết đơn', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isDeliveryPhase && order.soLanGiaoThatBai > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Đã giao thất bại ${order.soLanGiaoThatBai} lần',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
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

                // NÚT HUỶ ĐƠN
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

                // NÚT BÁO GIAO THẤT BẠI
                if (_isDeliveryPhase) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleReportFailure,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Báo giao thất bại', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}