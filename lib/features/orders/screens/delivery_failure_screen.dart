import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../services/api_service.dart';

/// Màn hình Shipper báo cáo giao hàng thất bại.
/// Trả về `true` qua Navigator.pop khi đã gửi báo cáo thành công, để màn cha
/// (MapDeliveryScreen) biết đường thoát về Home.
class DeliveryFailureScreen extends StatefulWidget {
  final String maDonHang;
  final int soLanThatBaiHienTai; // Số lần đã thất bại trước đó (chưa tính lần này)
  final int soLanToiDa;

  const DeliveryFailureScreen({
    Key? key,
    this.maDonHang = 'LR-VN-10293', // TODO: nhận mã đơn thật khi MapDeliveryScreen được nối với DonHangModel
    this.soLanThatBaiHienTai = 1,
    this.soLanToiDa = 3,
  }) : super(key: key);

  @override
  State<DeliveryFailureScreen> createState() => _DeliveryFailureScreenState();
}

class _DeliveryFailureScreenState extends State<DeliveryFailureScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _warningOrange = const Color(0xFFEF8C2C);

  // TODO: Xác nhận lại với backend giá trị trangThaiMoi chính xác cho "giao thất bại"
  // (ví dụ: "GiaoThatBai", "ThatBai"...). Đang tạm để "GiaoThatBai".
  static const String _trangThaiGiaoThatBai = 'GiaoThatBai';

  late final OrderRepository _orderRepository;

  final List<String> _lyDoList = const [
    'Người nhận không nghe máy',
    'Người nhận vắng nhà',
    'Người nhận từ chối nhận hàng',
    'Sai địa chỉ / không tìm thấy',
    'Khác (ghi chú)',
  ];

  int _selectedIndex = 0; // Mặc định chọn lý do đầu tiên giống mockup
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isOtherReasonSelected => _selectedIndex == _lyDoList.length - 1;

  Future<void> _handleConfirm() async {
    // Nếu chọn "Khác" thì bắt buộc phải có ghi chú
    if (_isOtherReasonSelected && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ghi chú lý do thất bại.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      final String ghiChu = _isOtherReasonSelected
          ? _noteController.text.trim()
          : _lyDoList[_selectedIndex];

      await _orderRepository.updateOrderStatus(
        widget.maDonHang,
        maSp,
        _trangThaiGiaoThatBai,
        ghiChu: ghiChu,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi báo cáo giao thất bại: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'LÝ DO GIAO THẤT BẠI',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  _buildReasonList(),
                  if (_isOtherReasonSelected) ...[
                    const SizedBox(height: 12),
                    _buildNoteInput(),
                  ],
                  const SizedBox(height: 24),
                  _buildFeeWarningBanner(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo giao thất bại',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '#${widget.maDonHang}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    // Lần thất bại nếu xác nhận lần này = soLanThatBaiHienTai + 1
    final int lanThatBaiSauKhiXacNhan = widget.soLanThatBaiHienTai;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trạng thái đơn hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Lần thất bại: $lanThatBaiSauKhiXacNhan/${widget.soLanToiDa}',
                style: TextStyle(color: _warningOrange, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(widget.soLanToiDa, (index) {
              final bool isFilled = index < lanThatBaiSauKhiXacNhan;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index == widget.soLanToiDa - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: isFilled ? _warningOrange : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonList() {
    return Column(
      children: List.generate(_lyDoList.length, (index) {
        final bool isSelected = _selectedIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? _primaryRed : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? _primaryRed : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lyDoList[index],
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNoteInput() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Nhập lý do cụ thể...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryRed)),
      ),
    );
  }

  Widget _buildFeeWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E9),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Từ lần thất bại thứ 2, phí phát sinh sẽ được tính cho người gửi.',
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  disabledBackgroundColor: _primaryRed.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Xác nhận giao thất bại',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn sẽ được điều phối giao lại vào ca làm việc tiếp theo',
              style: TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}