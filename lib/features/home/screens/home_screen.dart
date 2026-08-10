import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../core/repositories/shipper_repository.dart';
import '../../../services/location_service.dart';
import '../../orders/screens/order_list_tab.dart';
import '../../profile/screens/profile_screen.dart';
import '../../orders/screens/order_accept_screen.dart'; 
import '../../wallet_cod/screens/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Quản lý tab hiện tại và tab trước đó
  int _currentIndex = 0;
  int _previousIndex = 0; 

  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);

  // Khai báo các biến để gọi API
  late OrderRepository _orderRepository;
  Future<List<DonHangModel>> _futureOrders = Future.value(<DonHangModel>[]);
  
  // Các biến quản lý API và trạng thái Trực tuyến 
  late ApiServices _apiService;
  bool _isOnline = false;
  bool _isUpdatingStatus = false;

  // Biến để ghi nhớ các đơn hàng đã hiện popup (tránh hiện spam liên tục)
  final Set<String> _notifiedOrderIds = {};

  // GPS lifecycle khi Shipper Online.
  late ShipperRepository _shipperRepository;
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSubscription;
  bool _isStartingLocationTracking = false;

  // Poll assignment riêng của Shipper khi đang online.
  Timer? _assignmentPollingTimer;
  bool _isCheckingAssignment = false;
  bool _isOpeningAssignment = false;

  @override
  void initState() {
    super.initState();
    
    // Đăng ký theo dõi vòng đời của app
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo API Service
    _apiService = ApiServices();
    _orderRepository = OrderRepository(_apiService);
    _shipperRepository = ShipperRepository(_apiService);
    
    // Mặc định mở app lên là Ngoại tuyến -> chưa gọi API đơn hàng
    _forceOfflineSilently();
  }

  @override
  void dispose() {
    _assignmentPollingTimer?.cancel();
    _stopLocationTracking();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Hàm lắng nghe khi tắt app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 'detached' là trạng thái khi người dùng vuốt tắt ứng dụng hoàn toàn
    if (state == AppLifecycleState.detached) {
      if (_isOnline) {
        _forceOfflineSilently();
      }
    }
  }

  // Hàm gọi API chuyển Ngoại tuyến "ngầm" (Không hiện thông báo, không loading)
  Future<void> _forceOfflineSilently() async {
    await _stopLocationTracking();

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');
      
      if (maSp != null && maSp.isNotEmpty) {
        final body = {
          "maShipper": maSp,
          "trangThaiMoi": "NgoaiTuyen"
        };

        // Gọi API ép về Ngoại tuyến
        await _apiService.post('/api/Shipper/doi-trang-thai-hoat-dong', body);
        
        if (mounted) {
          setState(() {
            _isOnline = false;
          });
          _stopAssignmentPolling();
        }
      }
    } catch (e) {
      debugPrint('Lỗi force offline: $e'); 
    }
  }

  // Hàm đồng bộ trạng thái từ Backend
  Future<void> _fetchInitialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maTk = prefs.getString('maTk');
      if (maTk != null && maTk.isNotEmpty) {
        final response = await _apiService.get('/api/Auth/profile/$maTk');
        if (mounted) {
          setState(() {
            final chiTiet = response['chiTiet'] ?? {};
            _isOnline = chiTiet['trangThaiHoatDong'] == 'TrucTuyen';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy trạng thái ban đầu ở Home: $e');
    }

    // Đồng bộ danh sách đơn hàng theo đúng trạng thái vừa lấy được
    if (_isOnline) {
      await _loadOrders();
      _startAssignmentPolling();
      await _startLocationTracking(showPermissionError: false);
    } else {
      _stopAssignmentPolling();
      await _stopLocationTracking();
      _clearOrders();
    }
  }

  // Gọi API lấy DANH SÁCH ĐƠN CHỜ NHẬN khi đang Trực tuyến
  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final maSp = prefs.getString('maSp');

    if (maSp == null || maSp.isEmpty) {
      _clearOrders();
      return;
    }

    if (mounted) {
      setState(() {
        _futureOrders = _orderRepository.getAssignedOrdersWaitingConfirmation(maSp);
      });
    }
  }

  void _startAssignmentPolling() {
    _assignmentPollingTimer?.cancel();

    if (!_isOnline) return;

    _checkAssignedOrdersAndPrompt();
    _assignmentPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkAssignedOrdersAndPrompt(),
    );
  }

  void _stopAssignmentPolling() {
    _assignmentPollingTimer?.cancel();
    _assignmentPollingTimer = null;
  }

  Future<void> _checkAssignedOrdersAndPrompt() async {
    if (!_isOnline || _isCheckingAssignment || _isOpeningAssignment || !mounted) {
      return;
    }

    _isCheckingAssignment = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) return;

      final orders = await _orderRepository.getAssignedOrdersWaitingConfirmation(maSp);

      if (!mounted) return;

      setState(() {
        _futureOrders = Future.value(orders);
      });

      // Kiểm tra nếu có đơn ChoShipperXacNhan thì popup (chống spam bằng _notifiedOrderIds)
      for (var order in orders) {
        if (order.trangThai == 'ChoShipperXacNhan' && !_notifiedOrderIds.contains(order.maDh)) {
          _notifiedOrderIds.add(order.maDh); 
          _showAssignedOrderPopup(order);
          break; // Chỉ popup 1 đơn mỗi lần
        }
      }
    } catch (e) {
      debugPrint('Lỗi polling đơn được chỉ định: $e');
    } finally {
      _isCheckingAssignment = false;
    }
  }

  // Hàm hiển thị Popup khi phát hiện đơn được admin chỉ định
  void _showAssignedOrderPopup(DonHangModel order) {
    _isOpeningAssignment = true; // Chặn polling popup các đơn khác khi đang mở

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.local_shipping, color: _primaryRed),
              const SizedBox(width: 8),
              const Text('Đơn hàng chỉ định!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Admin vừa phân công trực tiếp cho bạn đơn hàng ${order.maDh}.\nBạn có muốn xem chi tiết và nhận ngay không?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isOpeningAssignment = false;
                Navigator.pop(context);
              },
              child: const Text('Để sau', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); 
                
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderAcceptScreen(maDh: order.maDh),
                  ),
                );
                
                _isOpeningAssignment = false;
                if (mounted && _isOnline) {
                  await _loadOrders(); // Tải lại danh sách sau khi xem chi tiết
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xem ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  // Xoá danh sách đơn hàng khi chuyển sang Ngoại tuyến (không gọi API)
  void _clearOrders() {
    if (mounted) {
      setState(() {
        _futureOrders = Future.value(<DonHangModel>[]);
      });
    }
  }
  
  Future<void> _sendGpsPosition(String maSp, Position position) async {
    await _shipperRepository.updateGpsLocation(
      maShipper: maSp,
      kinhDo: position.longitude,
      viDo: position.latitude,
    );

    debugPrint('[SHIPPER_GPS] Sent lat=${position.latitude}, lng=${position.longitude}');
  }

  Future<void> _startLocationTracking({bool showPermissionError = true}) async {
    if (_isStartingLocationTracking) return;

    _isStartingLocationTracking = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper để cập nhật GPS.');
      }

      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Gửi GPS ngay 1 lần khi vừa Online.
      final currentPosition = await _locationService.getCurrentPosition();

      if (!_isOnline) return;

      await _sendGpsPosition(maSp, currentPosition);

      if (!_isOnline) return;

      // Sau đó chỉ gửi tiếp khi di chuyển ít nhất 15m.
      _positionSubscription = _locationService
          .watchPosition(distanceFilterMeters: 15)
          .listen(
        (position) async {
          if (!_isOnline) return;
          try {
            await _sendGpsPosition(maSp, position);
          } catch (e) {
            debugPrint('[SHIPPER_GPS] Update failed: $e');
          }
        },
        onError: (Object error) {
          debugPrint('[SHIPPER_GPS] Stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('[SHIPPER_GPS] Start tracking failed: $e');

      if (showPermissionError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      _isStartingLocationTracking = false;
    }
  }

  Future<void> _stopLocationTracking() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;

    if (subscription != null) {
      await subscription.cancel();
      debugPrint('[SHIPPER_GPS] Tracking stopped');
    }
  }

  // Hàm chuyển đổi trạng thái khi bấm nút trên màn hình
  Future<void> _toggleOnlineStatus() async {
    setState(() {
      _isUpdatingStatus = true; 
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không tìm thấy mã Shipper!')),
        );
        return;
      }

      final newValue = !_isOnline; 
      final trangThaiMoi = newValue ? 'TrucTuyen' : 'NgoaiTuyen';

      final body = {
        "maShipper": maSp,
        "trangThaiMoi": trangThaiMoi
      };

      await _apiService.post('/api/Shipper/doi-trang-thai-hoat-dong', body);

      if (mounted) {
        setState(() {
          _isOnline = newValue;
        });
      }

      if (newValue) {
        await _loadOrders();
        _startAssignmentPolling();
        await _startLocationTracking();
      } else {
        _stopAssignmentPolling();
        await _stopLocationTracking();
        _clearOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  // ====================================================================================
  // PHẦN BÊN DƯỚI LÀ GIAO DIỆN UI
  // ====================================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _buildBodyContent(),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      title: Row(
        children: [
          const CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Text(
            'LogiRoute',
            style: TextStyle(
              color: _primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const OrderListTab();  
      case 2:
        return const FinanceTab();
      case 3:
        return ProfileScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = _previousIndex; 
            });
            if (_previousIndex == 0) {
              _fetchInitialStatus();
            }
          },
        );
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            const Text(
              'Đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildOrderSection(), 
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSection() {
    if (!_isOnline) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded, size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              const Text(
                'Bạn đang Ngoại tuyến.\nBật Trực tuyến để bắt đầu nhận đơn hàng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<DonHangModel>>(
      future: _futureOrders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } 
        else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Lỗi tải đơn hàng: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } 
        else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Chưa có đơn nào được Admin chỉ định cho bạn.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        final orders = snapshot.data!.take(5).toList();
        return Column(
          children: [
            for (int i = 0; i < orders.length; i++) ...[
              _buildOrderCard(orders[i]),
              if (i != orders.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUpdatingStatus ? null : _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300), 
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 48),
              decoration: BoxDecoration(
                color: _isOnline ? _primaryRed : Colors.white, 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _isOnline ? Colors.transparent : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: _isUpdatingStatus
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _isOnline ? Colors.white : _primaryRed, 
                      ),
                    )
                  : Text(
                      _isOnline ? 'Trực tuyến' : 'Ngoại tuyến',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? Colors.white : Colors.black87, 
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isOnline 
                ? 'Bạn sẽ nhận đơn mới khi đang Trực tuyến'
                : 'Đang nghỉ ngơi, bạn sẽ không nhận đơn',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('ĐƠN HÔM NAY', '12')),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatItem('COD ĐANG G...', '1.250.000', valueColor: Colors.deepOrange),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildStatItem('QUÃNG ĐƯỜ...', '45.8')),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _trangThaiLabel(String trangThai) {
    switch (trangThai) {
      case 'ChoXacNhan':
        return 'Chờ điều phối';
      case 'ChoShipperXacNhan':
        return 'Chờ bạn xác nhận';
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

  Widget _buildOrderCard(DonHangModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.maDh, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _trangThaiLabel(order.trangThai), 
                  style: TextStyle(
                    color: _primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                order.tenNguoiNhan, 
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.diaChiGiao, 
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderAcceptScreen(maDh: order.maDh),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text(
                'XEM CHI TIẾT',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.local_shipping_outlined, 'Orders', 1),
            _buildNavItem(Icons.account_balance_wallet_outlined, 'Finance', 2),
            _buildNavItem(Icons.person_outline, 'Profile', 3),
          ],
        ),
      ),
    );
  }

 Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() {
            _previousIndex = _currentIndex; 
            _currentIndex = index; 
          });
          
          if (index == 0) {
            _fetchInitialStatus();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), 
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.circular(12),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade800,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}