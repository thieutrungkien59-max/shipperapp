import 'package:flutter/material.dart';

class CameraProofScreen extends StatefulWidget {
  final bool isDeliveryPhase;
  
  const CameraProofScreen({Key? key, required this.isDeliveryPhase}) : super(key: key);

  @override
  State<CameraProofScreen> createState() => _CameraProofScreenState();
}

class _CameraProofScreenState extends State<CameraProofScreen> {
  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);
  final Color _successGreen = const Color(0xFF198754);

  bool _isPhotoTaken = false; 
  bool _isAuthComplete = false; // Biến mới: Theo dõi trạng thái xác thực (OTP/Chữ ký)
  int _selectedAuthTab = 1; 
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.isDeliveryPhase ? 'Nguyễn Văn A' : 'Trần Văn B',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningBanner(),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Minh chứng 1 — Ảnh gói hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoProofSection(),
                  const SizedBox(height: 24),

                  const Text(
                    'Minh chứng 2 — Xác thực',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildAuthToggle(),
                  const SizedBox(height: 24),
                  
                  // Hiển thị giao diện tương ứng với tab được chọn
                  if (_selectedAuthTab == 1) _buildOtpSection(),
                  if (_selectedAuthTab == 0) _buildSignatureSection(),
                  
                  const SizedBox(height: 24),
                  Text(
                    widget.isDeliveryPhase ? 'Tên người nhận thực tế' : 'Tên người gửi thực tế',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
          Text(
            widget.isDeliveryPhase ? 'Xác nhận giao hàng' : 'Xác nhận lấy hàng',
            style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
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
        color: const Color(0xFFFEF3E9),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
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
        setState(() { _isPhotoTaken = !_isPhotoTaken; });
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPhotoTaken ? Colors.transparent : Colors.grey.shade400,
            width: 1.5,
          ),
          image: _isPhotoTaken
              ? const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1616423640778-28d1b53229bd?q=80&w=600'),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _isPhotoTaken
            ? Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: _successGreen, borderRadius: BorderRadius.circular(20)),
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
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
              onTap: () {
                setState(() {
                  _selectedAuthTab = 0;
                  _isAuthComplete = false; // Reset trạng thái khi chuyển tab
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedAuthTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedAuthTab == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Chữ ký',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _selectedAuthTab == 0 ? Colors.black87 : Colors.grey.shade700),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAuthTab = 1;
                  _isAuthComplete = false; // Reset trạng thái khi chuyển tab
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedAuthTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _selectedAuthTab == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Nhập OTP',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _selectedAuthTab == 1 ? Colors.black87 : Colors.grey.shade700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN OTP GIẢ LẬP ---
  Widget _buildOtpSection() {
    return GestureDetector(
      onTap: () {
        // Bấm vào khung OTP để giả lập việc nhập mã thành công/thất bại
        setState(() {
          _isAuthComplete = !_isAuthComplete;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF7F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Text(
              'Mã 6 số đã được gửi đến SĐT ${widget.isDeliveryPhase ? "người nhận" : "người gửi"}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOtpBox(_isAuthComplete ? '1' : ''), 
                _buildOtpBox(_isAuthComplete ? '5' : ''), 
                _buildOtpBox(_isAuthComplete ? '9' : ''),
                _buildOtpBox(_isAuthComplete ? '0' : ''), 
                _buildOtpBox(_isAuthComplete ? '2' : ''), 
                _buildOtpBox(_isAuthComplete ? '6' : ''),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isAuthComplete ? 'Đã nhập đủ mã OTP (Nhấn để xóa)' : '(Nhấn vào khu vực này để điền nhanh OTP)',
              style: TextStyle(fontSize: 11, color: _isAuthComplete ? _successGreen : Colors.grey.shade500),
            ),
          ],
        ),
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
        border: Border.all(color: digit.isNotEmpty ? _primaryRed : Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  // --- GIAO DIỆN CHỮ KÝ GIẢ LẬP ---
  Widget _buildSignatureSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isAuthComplete = !_isAuthComplete;
        });
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF7F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isAuthComplete ? Icons.draw : Icons.edit_outlined, 
                size: 32, 
                color: _isAuthComplete ? _successGreen : Colors.grey.shade400
              ),
              const SizedBox(height: 8),
              Text(
                _isAuthComplete ? 'Đã ký tên thành công\n(Nhấn để hủy)' : 'Nhấn vào đây để giả lập Ký tên',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isAuthComplete ? _successGreen : Colors.grey.shade600,
                  fontWeight: _isAuthComplete ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryRed)),
      ),
    );
  }

  Widget _buildBottomAction() {
    // ĐIỀU KIỆN ĐỂ NÚT HOÀN THÀNH SÁNG LÊN
    bool isFormValid = _isPhotoTaken && _isAuthComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: SafeArea(
        child: Column(
          children: [
            const Text('Nút sẽ được kích hoạt khi đã đủ minh chứng bắt buộc', style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                // Nếu chưa đủ điều kiện -> onPressed = null (nút tự động bị mờ/disable)
                onPressed: isFormValid ? () {
                  Navigator.pop(context, true);
                } : null,
                style: ElevatedButton.styleFrom(
                  // Thay đổi màu nền tùy theo trạng thái hợp lệ
                  backgroundColor: isFormValid ? _primaryRed : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300, // Màu khi bị disable
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Hoàn thành', 
                  style: TextStyle(
                    color: isFormValid ? Colors.white : Colors.grey.shade500, // Đổi màu chữ tương ứng
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  )
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Ảnh được tự động nén để tối ưu dung lượng (max 2MB)', style: TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}