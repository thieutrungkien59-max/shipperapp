import 'package:flutter/material.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../orders/screens/order_list_tab.dart';
import '../../profile/screens/profile_screen.dart';
import '../../orders/screens/order_accept_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Quản lý tab hiện tại và tab trước đó
  int _currentIndex = 0;
  int _previousIndex = 0; 

  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);

  // Khai báo các biến để gọi API
  late OrderRepository _orderRepository;
  late Future<List<DonHangModel>> _futureOrders;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Repository với API Service
    _orderRepository = OrderRepository(ApiServices());
    
    // Gọi hàm lấy danh sách đơn hàng. 
    // LƯU Ý: Tạm thời dùng mã shipper cứng (ví dụ: 'SHIPPER_01'). 
    // Sau khi làm tính năng Đăng nhập, chúng ta sẽ lấy mã này từ dữ liệu User đã lưu.
    _futureOrders = _orderRepository.getOrdersByShipper('SHIPPER_01'); 
  }

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
        return const Center(child: Text('Màn hình Tài chính (Finance)'));
      case 3:
        return ProfileScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = _previousIndex; 
            });
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

  // Khu vực xử lý hiển thị API bằng FutureBuilder
  Widget _buildOrderSection() {
    return FutureBuilder<List<DonHangModel>>(
      future: _futureOrders,
      builder: (context, snapshot) {
        // Trạng thái 1: Đang chờ tải dữ liệu từ API
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } 
        // Trạng thái 2: API trả về lỗi
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
        // Trạng thái 3: Call API thành công nhưng danh sách rỗng
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

        // Trạng thái 4: Có dữ liệu, lấy phần tử đầu tiên hiển thị lên Home
        final firstOrder = snapshot.data!.first;
        return _buildOrderCard(firstOrder);
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            ),
            child: const Text(
              'Trực tuyến',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn sẽ nhận đơn mới khi đang Trực tuyến',
            style: TextStyle(color: Colors.grey, fontSize: 14),
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