import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart'; // Đảm bảo đường dẫn này đúng với project của bạn

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBackPressed;
  
  const ProfileScreen({Key? key, required this.onBackPressed}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Trạng thái màn hình
  bool _isLoading = true;
  String _errorMessage = '';

  // Các biến chứa dữ liệu từ API
  String _hoTen = '';
  String _soDienThoai = '';
  String _cccd = '';
  String _gplx = '';
  String _bienSoXe = '';
  String _loaiPhuongTien = '';
  String _taiTrongToiDa = '';
  bool _isApproved = false;
  
  // Màu sắc chủ đạo 
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _approvedColor = const Color(0xFF28A745);
  final Color _lockedColor = const Color(0xFFDC3545);
  final Color _primaryRed = const Color(0xFFE51D35);

  late final ApiServices _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiServices();
    _fetchProfileData();
  }

  // Hàm gọi API lấy dữ liệu Hồ sơ
  Future<void> _fetchProfileData() async {
    try {
      // 1. Lấy mã Shipper đã lưu lúc Đăng nhập
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy phiên đăng nhập. Vui lòng đăng nhập lại.');
      }

      // 2. Gọi API lấy thông tin (LƯU Ý: Thay đổi '/Shipper/$maSp' thành đúng đường dẫn Swagger của nhóm bạn)
      final response = await _apiService.get('/Shipper/cccd');

      // 3. Cập nhật giao diện
      if (mounted) {
        setState(() {
          _hoTen = response['hoTen'] ?? 'Chưa cập nhật';
          _soDienThoai = response['soDienThoai'] ?? '';
          _cccd = response['cccd'] ?? 'Đang trống';
          _gplx = response['gplx'] ?? 'Đang trống';
          _bienSoXe = response['bienSoXe'] ?? 'Đang trống';
          _loaiPhuongTien = response['loaiPhuongTien'] ?? 'Đang trống';
          _taiTrongToiDa = '${response['taiTrongToiDa'] ?? 0} kg';
          
          // Kiểm tra trạng thái hồ sơ (Dựa theo giá trị Backend trả về)
          final trangThai = response['trangThaiHoSo']?.toString().toLowerCase() ?? '';
          _isApproved = trangThai.contains('daduyet') || trangThai.contains('đã duyệt');
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE51D35)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
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
        Text(
          _hoTen,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _soDienThoai,
          style: const TextStyle(
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
            _isApproved ? 'ĐÃ DUYỆT' : 'CHỜ DUYỆT / KHÓA',
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
              _buildStatColumn('TỔNG ĐƠN', '0'), // Có thể map API thống kê vào đây sau
              _buildVerticalDivider(),
              _buildStatColumn('THÀNH CÔNG', '0%', valueColor: _approvedColor),
              _buildVerticalDivider(),
              _buildStatColumn('ĐÁNH GIÁ', '0 ⭐'),
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
          _buildInfoRow('CCCD', _cccd),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('GPLX', _gplx),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Đăng ký xe', _bienSoXe),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Loại phương tiện', _loaiPhuongTien),
          const Divider(height: 24, thickness: 1),
          _buildInfoRow('Tải trọng tối đa', _taiTrongToiDa),
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