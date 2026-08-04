import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/location_service.dart';

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

class FullMapScreen extends StatefulWidget {
  final DonHangModel order;
  final bool isDeliveryPhase;

  const FullMapScreen({Key? key, required this.order, required this.isDeliveryPhase}) : super(key: key);

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);

  final MapController _mapController = MapController();
  late final LocationService _locationService;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentLatLng;
  String? _gpsError;

  // --- Khung thông tin vuốt ---
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  static const List<double> _sheetSnapSizes = [0.06, 0.35, 0.60];
  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.35);

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    
    // Đồng bộ vị trí nút định vị theo thẻ vuốt
    _sheetController.addListener(() {
      if (_sheetController.isAttached) {
        _sheetExtent.value = _sheetController.size;
      }
    });

    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      final initialPosition = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);
      });
      _mapController.move(_currentLatLng!, 15);

      _positionSubscription = _locationService.watchPosition().listen((position) {
        if (!mounted) return;
        setState(() => _currentLatLng = LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _gpsError = e.toString().replaceAll('Exception: ', ''));
      }
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

  void _recenterToCurrentLocation() {
    if (_currentLatLng != null) {
      _mapController.move(_currentLatLng!, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ
          if (_currentLatLng == null)
            Center(
              child: _gpsError != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_gpsError!, textAlign: TextAlign.center),
                    )
                  : const CircularProgressIndicator(),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _currentLatLng!, initialZoom: 15),
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
            ),

          // 2. NÚT ĐỊNH VỊ (Tự động di chuyển theo BottomSheet)
          ValueListenableBuilder<double>(
            valueListenable: _sheetExtent,
            builder: (context, extent, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              final bottomPosition = (screenHeight * extent) + 16;
              return Positioned(
                bottom: bottomPosition,
                right: 16,
                child: _CircleIconButton(
                  icon: Icons.my_location,
                  onTap: _recenterToCurrentLocation,
                ),
              );
            },
          ),

          // 3. THẺ VUỐT THÔNG TIN ĐƠN HÀNG
          _buildDraggableBottomSheet(context),

          // 4. NÚT QUAY LẠI (Nằm trên cùng)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM DỰNG THẺ VUỐT ---
  Widget _buildDraggableBottomSheet(BuildContext context) {
    return ScrollConfiguration(
      behavior: _MouseDragScrollBehavior(),
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.35, 
        minChildSize: 0.06, // Hạ xuống 6% để chỉ còn thanh xám
        maxChildSize: 0.60,     
        snap: true,
        snapSizes: _sheetSnapSizes,
        builder: (context, scrollController) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                // === KHU VỰC TAY CẦM VUỐT CHÍNH THỨC CỦA FLUTTER ===
                // Dùng ListView gắn scrollController để Flutter tự nhận diện thao tác kéo thả
                SizedBox(
                  height: 36, // Vùng nhận thao tác vuốt (thanh xám)
                  child: ListView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(), // Ép nhận thao tác vuốt
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        height: 36,
                        color: Colors.transparent, // Phải có màu trong suốt để không bị lọt chuột
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

                // === KHU VỰC NỘI DUNG (CUỘN ĐỘC LẬP) ===
                Expanded(
                  child: ListView(
                    // Không gắn scrollController ở đây để chữ trượt không kéo theo thẻ
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Text(
                        'THÔNG TIN LỘ TRÌNH',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 16),
                      // Địa chỉ lấy
                      _addressRow(
                        icon: Icons.storefront_outlined,
                        label: 'Lấy hàng',
                        address: widget.order.diaChiLay,
                        iconColor: Colors.orange.shade700,
                      ),
                      
                      // Dấu gạch nối
                      Padding(
                        padding: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
                        child: Container(
                          width: 2, height: 20,
                          color: Colors.grey.shade300,
                        ),
                      ),

                      // Địa chỉ giao
                      _addressRow(
                        icon: Icons.location_on_outlined,
                        label: 'Giao đến',
                        address: widget.order.diaChiGiao,
                        iconColor: _primaryRed,
                      ),
                      
                      const SizedBox(height: 24),
                      // Thông tin người nhận
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _primaryRed.withOpacity(0.1),
                              child: Icon(Icons.person_outline, color: _primaryRed),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.order.tenNguoiNhan,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Người nhận',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _addressRow({required IconData icon, required String label, required String address, required Color iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}