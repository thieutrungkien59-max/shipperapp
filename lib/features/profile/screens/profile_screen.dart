import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  // Yêu cầu 1: Khai báo hàm callback để xử lý nút quay lại
  final VoidCallback onBackPressed;
  
  const ProfileScreen({Key? key, required this.onBackPressed}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Biến giả lập trạng thái từ Database: true = Đã duyệt, false = Bị khóa
  final bool _isApproved = true; 
  
  // Màu sắc chủ đạo 
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _approvedColor = const Color(0xFF28A745); // Xanh lá
  final Color _lockedColor = const Color(0xFFDC3545); // Đỏ
  final Color _primaryRed = const Color(0xFFE51D35);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // --- Thanh Custom Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      // Gọi hàm được truyền từ HomeScreen để quay lại tab trước
                      widget.onBackPressed();
                    },
                  ),
                  const Text(
                    'Hồ sơ của tôi',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    onPressed: () {
                      debugPrint('Mở tính năng chỉnh sửa hồ sơ');
                    },
                  ),
                ],
              ),
              // ----------------------------------------------------------------------
              const SizedBox(height: 16),
              _buildAvatarAndName(),
              const SizedBox(height: 12),
              _buildStatusBadge(),
              const SizedBox(height: 24),
              _buildPerformanceStats(),
              const SizedBox(height: 16),
              _buildPersonalInfo(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarAndName() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _approvedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Nguyễn Văn A',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '0901 234 567',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _isApproved ? _approvedColor : _lockedColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isApproved ? Icons.check_circle_outline : Icons.lock_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _isApproved ? 'ĐÃ DUYỆT' : 'BỊ KHÓA',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê hiệu suất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn('TỔNG ĐƠN', '1,248'),
              _buildVerticalDivider(),
              _buildStatColumn('THÀNH CÔNG', '98.5%', valueColor: _approvedColor),
              _buildVerticalDivider(),
              _buildStatColumn('ĐÁNH GIÁ', '4.9 ⭐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildPersonalInfo() {
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
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('CCCD', '079xxxxxxxxx'),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('GPLX', '123456789012'),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Đăng ký xe', '59-X1 123.45'),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Loại phương tiện', 'Xe máy'),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Tải trọng tối đa', '50kg'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}