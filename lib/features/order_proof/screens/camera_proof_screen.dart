import 'package:flutter/material.dart';

class CameraProofScreen extends StatefulWidget {
  const CameraProofScreen({Key? key}) : super(key: key);

  @override
  State<CameraProofScreen> createState() => _CameraProofScreenState();
}

class _CameraProofScreenState extends State<CameraProofScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _successGreen = const Color(0xFF198754);

  // Mặc định là false để hiển thị khung chưa chụp ảnh như bản thiết kế
  bool _isPhotoTaken = false; 
  int _selectedAuthTab = 1; // 0: Chữ ký, 1: Nhập OTP

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningBanner(),
                  const SizedBox(height: 24),
                  
                  // Minh chứng 1
                  const Text(
                    'Minh chứng 1 — Ảnh gói hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoProofSection(),
                  const SizedBox(height: 24),

                  // Minh chứng 2
                  const Text(
                    'Minh chứng 2 — Xác thực',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAuthToggle(),
                  const SizedBox(height: 24),
                  
                  // Nội dung thay đổi theo Tab
                  if (_selectedAuthTab == 1) _buildOtpSection(),
                  if (_selectedAuthTab == 0) const Center(child: Text('Giao diện ký tên (bổ sung sau)')),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Tên người gửi thực tế', // Cập nhật cho đúng ngữ cảnh lấy hàng
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildNameInput(),
                  const SizedBox(height: 32),
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
            'Xác nhận lấy hàng', // Đã cập nhật tiêu đề
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'LR-VN-10293',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E9), // Cam nhạt
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: Colors.orange, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: 'Đơn hàng '),
                  TextSpan(text: '≥ 1.000.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' — cần đủ 2 minh chứng'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoProofSection() {
    return GestureDetector(
      onTap: () {
        // Tương lai sẽ gọi thư viện image_picker ở đây
        setState(() {
          _isPhotoTaken = !_isPhotoTaken;
        });
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          // Tạo viền trơn
          border: Border.all(
            color: _isPhotoTaken ? Colors.transparent : Colors.grey.shade400,
            width: 1.5,
          ),
          image: _isPhotoTaken
              ? const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1616423640778-28d1b53229bd?q=80&w=600'), // Ảnh kiện hàng giả lập
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _isPhotoTaken
            ? Stack(
                children: [
                  // Badge "Đã chụp"
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _successGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Đã chụp', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  // Nút chụp lại (Retake)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh, color: Colors.black87, size: 24),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Nhấn để chụp ảnh gói hàng', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2E5E0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedAuthTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedAuthTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedAuthTab == 0
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Chữ ký',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedAuthTab == 0 ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedAuthTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedAuthTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedAuthTab == 1
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Nhập OTP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedAuthTab == 1 ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF7F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Text(
            'Mã 6 số đã được gửi đến SĐT người gửi', // Đã cập nhật người gửi
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOtpBox(''),
              _buildOtpBox(''),
              _buildOtpBox(''),
              _buildOtpBox(''),
              _buildOtpBox(''),
              _buildOtpBox(''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(String digit) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: TextEditingController(text: 'Trần Văn B'), // Đã cập nhật tên người gửi theo kịch bản
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryRed),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Text(
              'Nút sẽ được kích hoạt khi đã đủ minh chứng bắt buộc',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Hoàn thành',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ảnh được tự động nén để tối ưu dung lượng (max 2MB)',
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}