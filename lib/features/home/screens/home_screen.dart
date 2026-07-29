import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../orders/screens/order_list_tab.dart';
import '../../profile/screens/profile_screen.dart';
import '../../orders/screens/order_accept_screen.dart'; 
import '../../wallet_cod/screens/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ---> BƯỚC 1: Thêm "with WidgetsBindingObserver" vào class State <---
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Quản lý tab hiện tại và tab trước đó
  int _currentIndex = 0;
  int _previousIndex = 0; 

  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);

  // Khai báo các biến để gọi API
  late OrderRepository _orderRepository;
  late Future<List<DonHangModel>> _futureOrders;
  
  // Các biến quản lý API và trạng thái Trực tuyến 
  late ApiServices _apiService;
  bool _isOnline = false;
  bool _isUpdatingStatus = false; 

  @override
  void initState() {
    super.initState();
    
    // ---> BƯỚC 2: Đăng ký theo dõi vòng đời của app <---
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo API Service
    _apiService = ApiServices();
    _orderRepository = OrderRepository(_apiService);
    
    _futureOrders = _orderRepository.getOrdersByShipper('SHIPPER_01'); 
    
    // ---> BƯỚC 3: Mặc định mở app lên là Ngoại tuyến <---
    _forceOfflineSilently();
  }

  @override
  void dispose() {
    // ---> BƯỚC 4: Hủy đăng ký theo dõi khi tắt màn hình để tránh lỗi bộ nhớ <---
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---> BƯỚC 5: Hàm lắng nghe khi tắt app <---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 'detached' là trạng thái khi người dùng vuốt tắt ứng dụng hoàn toàn
    // Bạn cũng có thể thêm 'paused' (thu nhỏ app) nếu muốn thu nhỏ app cũng mất Trực tuyến
    if (state == AppLifecycleState.detached) {
      if (_isOnline) {
        _forceOfflineSilently();
      }
    }
  }

  // ---> BƯỚC 6: Hàm gọi API chuyển Ngoại tuyến "ngầm" (Không hiện thông báo, không loading) <---
  Future<void> _forceOfflineSilently() async {
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
            _isOnline = false; // Tắt đèn giao diện
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi force offline: $e'); // In ra console thay vì báo lỗi trên màn hình
    }
  }

  // ---> BỔ SUNG: Hàm đồng bộ trạng thái từ Backend <---
  Future<void> _fetchInitialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maTk = prefs.getString('maTk');
      if (maTk != null && maTk.isNotEmpty) {
        final response = await _apiService.get('/api/Auth/profile/$maTk');
        if (mounted) {
          setState(() {
            final chiTiet = response['chiTiet'] ?? {};
            final shipper = chiTiet['shipper'] ?? {};
            _isOnline = shipper['trangThaiHoatDong'] == 'TrucTuyen';
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy trạng thái ban đầu ở Home: $e');
    }
  } 
  
  // Hàm chuyển đổi trạng thái khi bấm nút trên màn hình (Giữ nguyên như cũ)
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
  // PHẦN BÊN DƯỚI LÀ GIAO DIỆN UI BẠN CỨ GIỮ NGUYÊN (Hàm build, _buildAppBar, _buildHomeTab, v.v...)
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
            // ---> BỔ SUNG: Nếu quay về Home thì gọi lại API lấy trạng thái <---
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
                'Hiện tại không có đơn hàng nào.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        final firstOrder = snapshot.data!.first;
        return _buildOrderCard(firstOrder);
      },
    );
  }

  // ---> BỔ SUNG: Giao diện thẻ Trực tuyến (Thiết kế mới bám sát ảnh) <---
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
                color: _isOnline ? _primaryRed : Colors.white, // Đổi nền 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _isOnline ? Colors.transparent : Colors.grey.shade400, // Thêm viền khi offline
                  width: 1.5,
                ),
              ),
              child: _isUpdatingStatus
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _isOnline ? Colors.white : _primaryRed, // Đổi màu vòng xoay tương phản với nền
                      ),
                    )
                  : Text(
                      _isOnline ? 'Trực tuyến' : 'Ngoại tuyến',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? Colors.white : Colors.black87, // Đổi màu chữ
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
                order.id, 
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
                  order.status, 
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
                order.customerName, 
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
                  order.address, 
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
                    builder: (context) => const OrderAcceptScreen(),
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
          
          // ---> BỔ SUNG: Khi bấm vào Tab 0 (Home), cập nhật lại trạng thái <---
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