// File: lib/features/orders/screens/order_list_tab.dart
//
// Đây KHÔNG phải 1 màn hình độc lập (không có Scaffold/AppBar/BottomNav).
// Đây là widget NỘI DUNG để nhúng vào case trong _buildBodyContent() của
// home_screen.dart, vì home_screen.dart đã tự quản lý AppBar + BottomNav
// dùng chung cho cả 4 tab (Home / Orders / Finance / Profile).
//
// MỤC ĐÍCH: hiển thị các đơn Shipper ĐÃ VÀ ĐANG PHỤ TRÁCH (mọi trạng thái:
// DaXacNhan, DangGiao, DaGiao, GiaoThatBai, DaHuy) — KHÔNG bao gồm đơn
// "ChoXacNhan" (đơn đó thuộc pool ở màn Home, chưa gán cho Shipper nào).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/don_hang_model.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/order_repository.dart';
import '../../map_tracking/screens/map_delivery_screen.dart';

class OrderListTab extends StatefulWidget {
  const OrderListTab({super.key});

  @override
  State<OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<OrderListTab> {
  static const Color _primaryRed = Color(0xFFE51D35);

  int _selectedTab = 0;
  final _tabs = const ['Tất cả', 'Đang xử lý', 'Hoàn tất', 'Thất bại'];

  late final OrderRepository _orderRepository;
  Future<List<DonHangModel>> _futureOrders = Future.value(<DonHangModel>[]);

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final maSp = prefs.getString('maSp');

    if (maSp == null || maSp.isEmpty) {
      setState(() {
        _futureOrders = Future.error(Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.'));
      });
      return;
    }

    setState(() {
      _futureOrders = _orderRepository.getOrdersByShipper(maSp);
    });
  }

  // Nhóm các trạng thái kỹ thuật vào 3 nhóm hiển thị: Đang xử lý / Hoàn tất / Thất bại
  bool _isDangXuLy(String trangThai) => trangThai == 'DaXacNhan' || trangThai == 'DangGiao';
  bool _isHoanTat(String trangThai) => trangThai == 'DaGiao';
  bool _isThatBai(String trangThai) => trangThai == 'GiaoThatBai' || trangThai == 'DaHuy' || trangThai == 'HuyTraHang';

  List<DonHangModel> _filterOrders(List<DonHangModel> orders) {
    // Phòng hờ: loại bỏ "ChoXacNhan" khỏi mọi tab, kể cả tab "Tất cả" -> đơn đó
    // thuộc pool nhận đơn ở Home, không phải đơn Shipper đang phụ trách.
    final ownedOrders = orders.where((o) => o.trangThai != 'ChoXacNhan').toList();

    switch (_selectedTab) {
      case 1:
        return ownedOrders.where((o) => _isDangXuLy(o.trangThai)).toList();
      case 2:
        return ownedOrders.where((o) => _isHoanTat(o.trangThai)).toList();
      case 3:
        return ownedOrders.where((o) => _isThatBai(o.trangThai)).toList();
      default:
        return ownedOrders;
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
          child: RefreshIndicator(
            color: _primaryRed,
            onRefresh: _loadOrders,
            child: FutureBuilder<List<DonHangModel>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildMessageState(
                    icon: Icons.error_outline,
                    message: 'Lỗi tải đơn hàng: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                  );
                }

                final orders = _filterOrders(snapshot.data ?? []);

                if (orders.isEmpty) {
                  return _buildMessageState(
                    icon: Icons.inventory_2_outlined,
                    message: 'Không có đơn hàng nào ở mục này.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageState({required IconData icon, required String message}) {
    return ListView(
      // Bọc trong ListView để RefreshIndicator vẫn vuốt để refresh được dù danh sách rỗng
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
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

  Widget _buildOrderCard(DonHangModel order) {
    // Các đơn còn đang xử lý (chưa hoàn tất/thất bại/huỷ) -> cho phép bấm vào để mở bản đồ
    final bool isActionable = order.trangThai == 'DaXacNhan' || order.trangThai == 'DangGiao';

    return GestureDetector(
      onTap: isActionable
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapDeliveryScreen(maDh: order.maDh)),
              );
            }
          : null,
      child: Container(
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
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _buildStatusBadge(order.trangThai),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.tenNguoiNhan,
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
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.diaChiGiao,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
            if (order.soLanGiaoThatBai > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Đã giao thất bại ${order.soLanGiaoThatBai} lần',
                style: const TextStyle(fontSize: 12, color: Color(0xFFC0392B), fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.tienCod.toStringAsFixed(0)}đ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD98A3D),
                  ),
                ),
                Text(
                  order.ngayTao != null ? _formatDateTime(order.ngayTao!) : '',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm $dd/$mo';
  }

  Widget _buildStatusBadge(String trangThai) {
    late final String label;
    late final Color bgColor;
    late final Color textColor;

    switch (trangThai) {
      case 'DaXacNhan':
        label = 'Đã xác nhận';
        bgColor = const Color(0xFFFBDCE0);
        textColor = const Color(0xFFC0392B);
        break;
      case 'DangGiao':
        label = 'Đang giao';
        bgColor = const Color(0xFFFBDCE0);
        textColor = const Color(0xFFC0392B);
        break;
      case 'DaGiao':
        label = 'Hoàn tất';
        bgColor = const Color(0xFFD9F2E3);
        textColor = const Color(0xFF2E9E5B);
        break;
      case 'GiaoThatBai':
        label = 'Giao thất bại';
        bgColor = const Color(0xFFFCE3C9);
        textColor = const Color(0xFFD07A2B);
        break;
      case 'DaHuy':
        label = 'Đã huỷ';
        bgColor = const Color(0xFFE5E5E5);
        textColor = const Color(0xFF616161);
        break;
      case 'HuyTraHang':
        label = 'Huỷ trả hàng';
        bgColor = const Color(0xFFE5E5E5);
        textColor = const Color(0xFF616161);
        break;
      default:
        label = trangThai;
        bgColor = const Color(0xFFE5E5E5);
        textColor = const Color(0xFF616161);
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