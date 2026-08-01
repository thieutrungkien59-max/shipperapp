import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/auth_repository.dart';

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
  late final TextEditingController _cccdCtrl;
  late final TextEditingController _gplxCtrl;
  late final TextEditingController _bienSoXeCtrl;
  late final TextEditingController _taiTrongToiDaCtrl;

  // Loại phương tiện dùng Dropdown thay vì nhập tay, đồng bộ với màn Đăng ký
  static const List<String> _phuongTienOptions = ['Xe máy', 'Xe ba gác', 'Xe tải nhỏ', 'Xe bán tải'];
  late String _selectedPhuongTien;

  bool _isSaving = false;

  final Color _primaryRed = const Color(0xFFE51D35);
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(ApiServices());

    // Không hiển thị các giá trị placeholder "Đang trống" / "Chưa cập nhật" trong ô nhập
    String clean(String value) {
      const placeholders = ['Đang trống', 'Chưa cập nhật'];
      return placeholders.contains(value) ? '' : value;
    }

    _hoTenCtrl = TextEditingController(text: clean(widget.hoTen));
    _soDienThoaiCtrl = TextEditingController(text: clean(widget.soDienThoai));
    _cccdCtrl = TextEditingController(text: clean(widget.cccd));
    _gplxCtrl = TextEditingController(text: clean(widget.gplx));
    _bienSoXeCtrl = TextEditingController(text: clean(widget.bienSoXe));
    _selectedPhuongTien = _phuongTienOptions.contains(widget.loaiPhuongTien)
        ? widget.loaiPhuongTien
        : _phuongTienOptions.first;
    _taiTrongToiDaCtrl = TextEditingController(
      text: widget.taiTrongToiDa > 0 ? widget.taiTrongToiDa.toString() : '',
    );
  }

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
    _cccdCtrl.dispose();
    _gplxCtrl.dispose();
    _bienSoXeCtrl.dispose();
    _taiTrongToiDaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final maSp = prefs.getString('maSp');

      if (maSp == null || maSp.isEmpty) {
        throw Exception('Không tìm thấy mã Shipper, vui lòng đăng nhập lại.');
      }

      await _authRepository.updateShipperProfile(
        maSp: maSp,
        hoTen: _hoTenCtrl.text.trim(),
        soDienThoai: _soDienThoaiCtrl.text.trim(),
        cccd: _cccdCtrl.text.trim(),
        gplx: _gplxCtrl.text.trim(),
        bienSoXe: _bienSoXeCtrl.text.trim(),
        loaiPhuongTien: _selectedPhuongTien,
        taiTrongToiDa: int.tryParse(_taiTrongToiDaCtrl.text.trim()) ?? 0,
      );

      if (!mounted) return;

      // Trả về true để màn Hồ sơ biết cần load lại dữ liệu mới
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildField(
                controller: _hoTenCtrl,
                label: 'Họ tên',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _soDienThoaiCtrl,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _cccdCtrl,
                label: 'CCCD',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _gplxCtrl,
                label: 'GPLX',
                icon: Icons.assignment_ind_outlined,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _bienSoXeCtrl,
                label: 'Biển số xe',
                icon: Icons.two_wheeler_outlined,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedPhuongTien,
                decoration: InputDecoration(
                  labelText: 'Loại phương tiện',
                  prefixIcon: Icon(Icons.local_shipping_outlined, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryRed),
                  ),
                ),
                items: _phuongTienOptions
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() => _selectedPhuongTien = newValue!);
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _taiTrongToiDaCtrl,
                label: 'Tải trọng tối đa (kg)',
                icon: Icons.scale_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                            color: Colors.white,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Không được để trống';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryRed),
        ),
      ),
    );
  }
}