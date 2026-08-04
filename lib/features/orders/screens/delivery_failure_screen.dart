import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../services/api_service.dart';
import '../../../models/don_hang_model.dart';

/// Màn hình Shipper báo cáo giao hàng thất bại.
/// Trả về DonHangModel (đã fetch lại mới nhất từ server) qua Navigator.pop khi gửi báo cáo
/// thành công, để màn cha (MapDeliveryScreen) biết đơn còn "DangGiao" (tiếp tục giao, chỉ tăng
/// soLanGiaoThatBai) hay đã bị server tự chuyển "GiaoThatBai" (đủ số lần thất bại tối đa, cần
/// thoát về Home). Trả về `null` nếu người dùng huỷ thao tác hoặc có lỗi.
class DeliveryFailureScreen extends StatefulWidget {
  final String maDonHang;
  final int soLanThatBaiHienTai; // Số lần đã thất bại trước đó (lấy từ order.soLanGiaoThatBai)
  final int soLanToiDa;

  const DeliveryFailureScreen({
    Key? key,
    required this.maDonHang,
    required this.soLanThatBaiHienTai,
    this.soLanToiDa = 3, // Chỉ mang tính hiển thị tham khảo; quyết định huỷ đơn thật do server trả về
  }) : super(key: key);

  @override
  State<DeliveryFailureScreen> createState() => _DeliveryFailureScreenState();
}

class _DeliveryFailureScreenState extends State<DeliveryFailureScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _warningOrange = const Color(0xFFEF8C2C);

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

      // LƯU Ý: chỉ "Khac" đã được backend xác nhận là giá trị lyDo chắc chắn hợp lệ.
      // Với lý do soạn sẵn (không phải "Khác"), mình vẫn gửi đúng mô tả tiếng Việt của lý do đó
      // (nhiều khả năng field này chỉ lưu mô tả tự do, không phải enum cứng) — nếu backend từ chối
      // (lỗi 400), báo lại để mình đổi sang gửi cố định "Khac" kèm mô tả thay vì gửi thẳng lý do.
      final String lyDo = _isOtherReasonSelected
          ? 'Khac: ${_noteController.text.trim()}'
          : _lyDoList[_selectedIndex];

      await _orderRepository.reportDeliveryFailure(
        maDonHang: widget.maDonHang,
        maShipper: maSp,
        lyDo: lyDo,
      );

      // Lấy lại dữ liệu đơn hàng mới nhất từ server (nguồn dữ liệu chuẩn duy nhất) để biết
      // chính xác: soLanGiaoThatBai đã tăng chưa, và trangThai còn "DangGiao" hay đã bị server
      // tự chuyển thành "GiaoThatBai" (khi đạt số lần tối đa).
      final updatedOrder = await _orderRepository.getOrderDetail(widget.maDonHang);

      if (!mounted) return;
      Navigator.pop(context, updatedOrder);
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
    final int lanThatBaiSauKhiXacNhan = widget.soLanThatBaiHienTai + 1;
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