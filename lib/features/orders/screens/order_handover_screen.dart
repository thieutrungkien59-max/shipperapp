import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repositories/order_repository.dart';
import '../../../services/api_service.dart';

/// Màn hình bàn giao đơn hàng giữa 2 Shipper (bàn giao dọc đường / đổi ca).
/// Trả về `true` qua Navigator.pop khi shipper tiếp nhận đã xác thực xong,
/// để màn cha (OrderDetailScreen / MapDeliveryScreen) biết đường xử lý tiếp.
class OrderHandoverScreen extends StatefulWidget {
  final String maDonHang;
  final String tenShipperBanGiao; // Shipper đang giao đơn, muốn bàn giao lại
  final String tenShipperTiepNhan; // Shipper hiện tại (BẠN) — người tiếp nhận

  const OrderHandoverScreen({
    Key? key,
    this.maDonHang = 'LR-VN-10293', // TODO: nhận mã đơn thật khi màn cha được nối với DonHangModel
    this.tenShipperBanGiao = 'Trần Văn B',
    this.tenShipperTiepNhan = 'Nguyễn Văn A', // TODO: lấy tên shipper hiện tại từ hồ sơ (ProfileScreen) thay vì hardcode
  }) : super(key: key);

  @override
  State<OrderHandoverScreen> createState() => _OrderHandoverScreenState();
}

class _OrderHandoverScreenState extends State<OrderHandoverScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _successGreen = const Color(0xFF198754);
  final Color _pendingOrange = const Color(0xFFEF8C2C);

  // TODO: Xác nhận lại với backend giá trị trangThaiMoi chính xác cho "bàn giao thành công"
  // (ví dụ: "DaBanGiao", "DaTiepNhan"...). Đang tạm để "DaBanGiao".
  static const String _trangThaiBanGiaoXong = 'DaBanGiao';

  late final OrderRepository _orderRepository;

  bool _isVerified = false; // true khi đã "quét QR" hoặc nhập đủ OTP (giả lập)
  bool _isPhotoTaken = false; // ảnh tình trạng hàng hóa lúc bàn giao (bắt buộc)
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderRepository = OrderRepository(ApiServices());
  }

  bool get _isFormValid => _isVerified && _isPhotoTaken;

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      await _orderRepository.updateOrderStatus(
        widget.maDonHang,
        maSp,
        _trangThaiBanGiaoXong,
        ghiChu: 'Bàn giao từ ${widget.tenShipperBanGiao} sang ${widget.tenShipperTiepNhan}',
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
            content: Text('Lỗi bàn giao đơn: ${e.toString().replaceAll('Exception: ', '')}'),
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
                  _buildStatusPill(),
                  const SizedBox(height: 16),
                  _buildShipperInfoCard(),
                  const SizedBox(height: 24),
                  _buildQrSection(),
                  const SizedBox(height: 16),
                  _buildOrDivider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhập mã OTP thủ công',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildOtpRow(),
                  const SizedBox(height: 24),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Ảnh tình trạng hàng hóa lúc bàn giao ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                        TextSpan(text: '*', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoProofBox(),
                  const SizedBox(height: 24),
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
            'Bàn giao đơn hàng',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            widget.maDonHang,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (_isVerified ? _successGreen : _pendingOrange).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isVerified ? Icons.check_circle_outline : Icons.pause_circle_outline,
              color: _isVerified ? _successGreen : _pendingOrange,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isVerified ? 'ĐÃ XÁC THỰC QR/OTP' : 'ĐANG CHỜ XÁC THỰC QR/OTP',
              style: TextStyle(
                color: _isVerified ? _successGreen : _pendingOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipperInfoCard() {
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
          _buildShipperRow('SHIPPER BÀN GIAO', widget.tenShipperBanGiao, Icons.person_outline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Icon(Icons.arrow_downward, color: Colors.grey.shade400, size: 18),
          ),
          _buildShipperRow('SHIPPER TIẾP NHẬN (BẠN)', widget.tenShipperTiepNhan, Icons.person, highlight: true),
        ],
      ),
    );
  }

  Widget _buildShipperRow(String label, String name, IconData icon, {bool highlight = false}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: highlight ? _primaryRed.withOpacity(0.12) : Colors.grey.shade200,
          child: Icon(icon, color: highlight ? _primaryRed : Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // --- GIẢ LẬP QUÉT QR (tap để bật/tắt xác thực, giống cách CameraProofScreen giả lập OTP) ---
  Widget _buildQrSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isVerified = !_isVerified;
            });
          },
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isVerified ? _successGreen : _primaryRed, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isVerified ? Icons.check_circle : Icons.qr_code_scanner,
                    size: 48,
                    color: _isVerified ? _successGreen : Colors.white70,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isVerified ? 'Đã quét thành công' : 'Đang chờ quét...',
                    style: TextStyle(color: _isVerified ? _successGreen : Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isVerified ? '(Nhấn lại vào khung để hủy xác thực)' : 'Quét mã QR từ Shipper bàn giao',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('HOẶC', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  // --- GIẢ LẬP NHẬP OTP (tap để điền nhanh, giống pattern trong CameraProofScreen) ---
  Widget _buildOtpRow() {
    const String demoOtp = '284915';
    return GestureDetector(
      onTap: () {
        setState(() {
          _isVerified = !_isVerified;
        });
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          final String digit = _isVerified ? demoOtp[index] : '0';
          return Container(
            width: 45,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isVerified ? _successGreen : Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          );
        }),
      ),
    );
  }

  // --- GIẢ LẬP CHỤP ẢNH (giống pattern _buildPhotoProofSection trong CameraProofScreen) ---
  Widget _buildPhotoProofBox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPhotoTaken = !_isPhotoTaken;
        });
      },
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPhotoTaken ? _successGreen : Colors.grey.shade400,
            width: _isPhotoTaken ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: _isPhotoTaken
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 40, color: _successGreen),
                  const SizedBox(height: 8),
                  Text('Đã chụp ảnh (Nhấn để chụp lại)', style: TextStyle(color: _successGreen, fontWeight: FontWeight.bold)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text('Chụp ảnh tình trạng hàng hóa', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
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
              child: ElevatedButton.icon(
                onPressed: (_isFormValid && !_isSubmitting) ? _handleConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : Icon(Icons.check_circle_outline, color: _isFormValid ? Colors.white : Colors.grey.shade500),
                label: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Xác nhận tiếp nhận đơn',
                        style: TextStyle(
                          color: _isFormValid ? Colors.white : Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lệnh Treo sẽ được gỡ ngay khi xác thực thành công',
              style: TextStyle(fontSize: 11, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}