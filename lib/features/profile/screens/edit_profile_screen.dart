import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String hoTen;
  final String soDienThoai;
  final String cccd;
  final String gplx;
  final String bienSoXe;
  final String loaiPhuongTien;
  final int taiTrongToiDa;

  const EditProfileScreen({
    Key? key,
    required this.hoTen,
    required this.soDienThoai,
    required this.cccd,
    required this.gplx,
    required this.bienSoXe,
    required this.loaiPhuongTien,
    required this.taiTrongToiDa,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hoTenCtrl;
  late final TextEditingController _soDienThoaiCtrl;

  bool _isSaving = false;

  final Color _primaryRed = const Color(0xFFE51D35);
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();

    _authRepository = AuthRepository(ApiServices());

    _hoTenCtrl = TextEditingController(text: _clean(widget.hoTen));
    _soDienThoaiCtrl = TextEditingController(text: _clean(widget.soDienThoai));
  }

  String _clean(String value) {
    const placeholders = {'Đang trống', 'Chưa cập nhật', '---'};

    final text = value.trim();
    return placeholders.contains(text) ? '' : text;
  }

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // VALIDATE HỌ TÊN
  // - bắt buộc
  // - 2..100 ký tự
  // - chữ Việt/Latin + space + . ' -
  // - không số / ký tự linh tinh
  // =========================================================
  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }

    if (name.length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }

    if (name.length > 100) {
      return 'Họ và tên tối đa 100 ký tự';
    }

    if (!RegExp(r"^[a-zA-ZÀ-ỹĐđ\s'.-]+$").hasMatch(name)) {
      return "Họ tên chỉ được chứa chữ, khoảng trắng, '.', '-' hoặc \"'\"";
    }

    if (RegExp(r'\s{2,}').hasMatch(name)) {
      return 'Không nhập nhiều khoảng trắng liên tiếp';
    }

    // Không chấp nhận chuỗi chỉ toàn dấu/khoảng trắng.
    if (!RegExp(r'[a-zA-ZÀ-ỹĐđ]').hasMatch(name)) {
      return 'Họ và tên phải chứa ký tự chữ';
    }

    return null;
  }

  // =========================================================
  // VALIDATE SĐT
  // - bắt buộc
  // - đúng 10 chữ số
  // - bắt đầu bằng 0
  // =========================================================
  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải gồm đúng 10 số và bắt đầu bằng 0';
    }

    return null;
  }

  String _normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s{2,}'), ' ');
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.trim().isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      final newName = _normalizeName(_hoTenCtrl.text);
      final newPhone = _soDienThoaiCtrl.text.trim();

      // FRONTEND RULE:
      // Shipper chỉ tự sửa Họ tên + SĐT.
      //
      // Repository hiện tại vẫn yêu cầu đủ các field, vì vậy các field
      // nhạy cảm được gửi lại NGUYÊN GIÁ TRỊ CŨ, không cho người dùng
      // sửa trên UI.
      //
      // TODO BACKEND:
      // Endpoint self-update phải tự chặn việc thay đổi:
      // CCCD/GPLX/Biển số/Loại phương tiện/Tải trọng.
      await _authRepository.updateShipperProfile(
        maSp: maSp,
        hoTen: newName,
        soDienThoai: newPhone,
        cccd: widget.cccd,
        gplx: widget.gplx,
        bienSoXe: widget.bienSoXe,
        loaiPhuongTien: widget.loaiPhuongTien,
        taiTrongToiDa: widget.taiTrongToiDa,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F8),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _buildInfoBanner(),

              const SizedBox(height: 22),

              const Text(
                'Thông tin có thể chỉnh sửa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const SizedBox(height: 14),

              _buildEditableField(
                controller: _hoTenCtrl,
                label: 'Họ và tên',
                hint: 'Ví dụ: Nguyễn Văn An',
                icon: Icons.person_outline,
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-ZÀ-ỹĐđ\s'.-]"),
                  ),
                  LengthLimitingTextInputFormatter(100),
                ],
              ),

              const SizedBox(height: 14),

              _buildEditableField(
                controller: _soDienThoaiCtrl,
                label: 'Số điện thoại',
                hint: 'Ví dụ: 0912345678',
                icon: Icons.phone_outlined,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              const SizedBox(height: 26),

              const Text(
                'Thông tin hồ sơ đã xác minh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Các thông tin dưới đây vui lòng liên hệ quản trị viên nếu cần thay đổi.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              _buildLockedField(
                label: 'CCCD',
                value: _display(widget.cccd),
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 12),

              _buildLockedField(
                label: 'GPLX',
                value: _display(widget.gplx),
                icon: Icons.assignment_ind_outlined,
              ),

              const SizedBox(height: 12),

              _buildLockedField(
                label: 'Biển số xe',
                value: _display(widget.bienSoXe),
                icon: Icons.two_wheeler_outlined,
              ),

              const SizedBox(height: 12),

              _buildLockedField(
                label: 'Loại phương tiện',
                value: _display(widget.loaiPhuongTien),
                icon: Icons.local_shipping_outlined,
              ),

              const SizedBox(height: 12),

              _buildLockedField(
                label: 'Tải trọng tối đa',
                value: widget.taiTrongToiDa > 0
                    ? '${widget.taiTrongToiDa} kg'
                    : 'Chưa cập nhật',
                icon: Icons.scale_outlined,
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primaryRed.withOpacity(0.45),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LƯU THAY ĐỔI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _display(String value) {
    final text = _clean(value);
    return text.isEmpty ? 'Chưa cập nhật' : text;
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryRed.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: _primaryRed),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bạn chỉ có thể tự cập nhật thông tin liên hệ. '
              'Thông tin giấy tờ và phương tiện đã được khóa để tránh làm sai hồ sơ đã duyệt.',
              style: TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}
