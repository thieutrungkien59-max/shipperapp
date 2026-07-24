import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

/// Màn hình "Đơn hàng của tôi" - danh sách đơn hàng với filter theo trạng thái
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

// ==== Model tạm cho UI (chưa nối API) ====
// TODO: thay bằng model thật trong lib/models/ khi nối dữ liệu
enum OrderStatus { delivering, completed, failed }

class OrderItem {
  final String code;
  final String customerName;
  final String address;
  final String price; // đã format sẵn, ví dụ "450,000đ"
  final String time; // ví dụ "10:30 24/05"
  final OrderStatus status;

  const OrderItem({
    required this.code,
    required this.customerName,
    required this.address,
    required this.price,
    required this.time,
    required this.status,
  });
}

// Dữ liệu mẫu để dựng giao diện - sẽ thay bằng dữ liệu từ ApiService sau
const _mockOrders = [
  OrderItem(
    code: 'LR-VN-10293',
    customerName: 'Nguyen Van A',
    address: '123 Tran Hung Dao, Quan 1, TP HCM',
    price: '450,000đ',
    time: '10:30 24/05',
    status: OrderStatus.delivering,
  ),
  OrderItem(
    code: 'LR-VN-10290',
    customerName: 'Tran Thi B',
    address: '456 Le Loi, Quan 1, TP HCM',
    price: '1,200,000đ',
    time: '09:15 24/05',
    status: OrderStatus.completed,
  ),
  OrderItem(
    code: 'LR-VN-10285',
    customerName: 'Le Van C',
    address: '789 Nguyen Hue, Quan 1, TP HCM',
    price: '0đ',
    time: '08:30 24/05',
    status: OrderStatus.failed,
  ),
  OrderItem(
    code: 'LR-VN-10280',
    customerName: 'Pham Thi D',
    address: '321 Vo Van Tan, Quan 3, TP HCM',
    price: '800,000đ',
    time: '17:00 23/05',
    status: OrderStatus.completed,
  ),
];

class _OrderListScreenState extends State<OrderListScreen> {
  // TODO: chuyển sang core/constants/app_colors.dart (xem ghi chú tương tự trong login_screen.dart)
  static const Color primaryRed = Color(0xFFE63946);
  static const Color backgroundBeige = Color(0xFFFBF3EE);
  static const Color textGrey = Color(0xFF8A8A8A);
  static const Color borderGrey = Color(0xFFE8E0DA);

  int _selectedTab = 0; // 0: Tất cả, 1: Đang xử lý, 2: Hoàn tất, 3: Thất bại
  final _tabs = const ['Tất cả', 'Đang xử lý', 'Hoàn tất', 'Thất bại'];

  List<OrderItem> get _filteredOrders {
    switch (_selectedTab) {
      case 1:
        return _mockOrders
            .where((o) => o.status == OrderStatus.delivering)
            .toList();
      case 2:
        return _mockOrders
            .where((o) => o.status == OrderStatus.completed)
            .toList();
      case 3:
        return _mockOrders
            .where((o) => o.status == OrderStatus.failed)
            .toList();
      default:
        return _mockOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 12),
            _buildFilterTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filteredOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _buildOrderCard(_filteredOrders[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Colors.black87),
          const SizedBox(width: 12),
          const Text(
            'Đơn hàng của tôi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryRed,
            ),
          ),
          const Spacer(),
          const Icon(Icons.search, color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primaryRed : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? primaryRed : borderGrey,
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.code,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.customerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: borderGrey),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD98A3D),
                ),
              ),
              Text(
                order.time,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    late final String label;
    late final Color bgColor;
    late final Color textColor;

    switch (status) {
      case OrderStatus.delivering:
        label = 'Đang giao';
        bgColor = const Color(0xFFFBDCE0);
        textColor = const Color(0xFFC0392B);
        break;
      case OrderStatus.completed:
        label = 'Hoàn tất';
        bgColor = const Color(0xFFD9F2E3);
        textColor = const Color(0xFF2E9E5B);
        break;
      case OrderStatus.failed:
        label = 'Giao thất bại';
        bgColor = const Color(0xFFFCE3C9);
        textColor = const Color(0xFFD07A2B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundBeige,
        border: Border(top: BorderSide(color: borderGrey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            'Trang chủ',
            false,
            onTap: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
          _buildNavItem(Icons.local_shipping_outlined, 'Đơn hàng', true),
          // TODO: nối 2 mục dưới đây khi có route Đối soát / Hồ sơ
          _buildNavItem(Icons.receipt_long_outlined, 'Đối soát', false),
          _buildNavItem(Icons.person_outline, 'Hồ sơ', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? primaryRed : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.black54,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? primaryRed : Colors.black54,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}