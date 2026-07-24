import 'package:flutter/material.dart';
import '../../order_proof/screens/camera_proof_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _successGreen = const Color(0xFF28A745);
  final Color _bgColor = const Color(0xFFFAF8F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Thanh tiến trình trạng thái đơn hàng
          _buildStatusStepper(),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Giả lập ảnh bản đồ lộ trình (thay bằng ảnh thật hoặc Google Map tĩnh sau)
                  _buildMapSnapshot(),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPickupAddressCard(),
                        const SizedBox(height: 16),
                        _buildPackageInfoCard(),
                        const SizedBox(height: 16),
                        _buildDropoffCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Nút bấm cố định dưới cùng
          _buildBottomButton(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết đơn hàng',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'LR-VN-10293',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepItem('Xác nhận đơn', isActive: true, isDone: true),
          _buildStepLine(isDone: true),
          _buildStepItem('Đang lấy\nhàng', isActive: true, isDone: false, isCurrent: true),
          _buildStepLine(isDone: false),
          _buildStepItem('Đang giao', isActive: false, isDone: false),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, {required bool isActive, required bool isDone, bool isCurrent = false}) {
    Color iconColor;
    if (isDone) {
      iconColor = _successGreen;
    } else if (isCurrent) {
      iconColor = _primaryRed;
    } else {
      iconColor = Colors.grey.shade300;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone || isCurrent ? iconColor : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone || isCurrent ? iconColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : (isCurrent
                    ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))
                    : null),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? _primaryRed : (isActive ? Colors.black87 : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine({required bool isDone}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 11),
        height: 2,
        color: isDone ? _successGreen : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildMapSnapshot() {
    return Container(
      width: double.infinity,
      height: 160,
      color: const Color(0xFFEAEAEA),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.map_outlined, size: 60, color: Colors.grey.shade400),
          const Text('Bản đồ lộ trình', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPickupAddressCard() {
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
          Text('ĐỊA CHỈ LẤY HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('45 Lê Duẩn, Quận 1, TP.HCM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions, color: Colors.black87, size: 20),
                  label: const Text('Chỉ đường', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone_outlined, color: Colors.black87),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfoCard() {
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
          Text('THÔNG TIN GÓI HÀNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          _buildInfoRow('Khối lượng (kg):', '12.5'),
          const SizedBox(height: 16),
          _buildInfoRow('Kích thước (D x R x C):', '30x20x15'),
          const SizedBox(height: 16),
          _buildInfoRow('Số tiền thu hộ COD (VNĐ):', '450.000', valueColor: Colors.orange.shade700),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Khung giờ lấy hàng dự kiến:', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E5E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('14:00 - 15:30', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDropoffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF5EBE9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GIAO ĐẾN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                const Text(
                  '12 Thảo Điền, Quận 2, TP.H...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraProofScreen()),
              );
            },
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
            label: const Text(
              'Xác nhận đã lấy hàng',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}