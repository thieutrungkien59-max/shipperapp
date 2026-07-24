// File: lib/features/orders/screens/order_list_tab.dart
//
// Đây KHÔNG phải 1 màn hình độc lập (không có Scaffold/AppBar/BottomNav).
// Đây là widget NỘI DUNG để nhúng vào case trong _buildBodyContent() của
// home_screen.dart, vì home_screen.dart đã tự quản lý AppBar + BottomNav
// dùng chung cho cả 4 tab (Home / Orders / Finance / Profile).
import 'package:flutter/material.dart';

enum OrderStatus { delivering, completed, failed }

class OrderItem {
  final String code;
  final String customerName;
  final String address;
  final String price;
  final String time;
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

// TODO: thay bằng dữ liệu thật từ DonHangModel / ApiService khi nối API
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

class OrderListTab extends StatefulWidget {
  const OrderListTab({super.key});

  @override
  State<OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<OrderListTab> {
  // Dùng chung màu đỏ với home_screen.dart để đồng bộ giao diện
  static const Color _primaryRed = Color(0xFFE51D35);

  int _selectedTab = 0;
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
        return _mockOrders.where((o) => o.status == OrderStatus.failed).toList();
      default:
        return _mockOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildFilterTabs(),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _filteredOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _buildOrderCard(_filteredOrders[index]),
          ),
        ),
      ],
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
                color: isSelected ? _primaryRed : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? _primaryRed : Colors.grey.shade300,
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
        border: Border.all(color: Colors.grey.shade200),
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
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade600),
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
          Divider(height: 1, color: Colors.grey.shade200),
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
}