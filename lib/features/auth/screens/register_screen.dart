import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Các Controllers cho Thông tin cá nhân
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Các Controllers cho Thông tin phương tiện & Giấy tờ
  final TextEditingController _cccdController = TextEditingController();
  final TextEditingController _gplxController = TextEditingController();
  final TextEditingController _bienSoXeController = TextEditingController();
  final TextEditingController _taiTrongController = TextEditingController();
  
  String _selectedPhuongTien = 'Xe máy'; // Giá trị mặc định cho Dropdown
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final Color _primaryRed = const Color(0xFFE51D35);
  final Color _bgColor = const Color(0xFFFAF8F8);

  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(ApiServices());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cccdController.dispose();
    _gplxController.dispose();
    _bienSoXeController.dispose();
    _taiTrongController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final isSuccess = await _authRepository.register(
          hoTen: _nameController.text.trim(),
          soDienThoai: _phoneController.text.trim(),
          password: _passwordController.text,
          cccd: _cccdController.text.trim(),
          gplx: _gplxController.text.trim(),
          bienSoXe: _bienSoXeController.text.trim(),
          loaiPhuongTien: _selectedPhuongTien,
          // Chuyển đổi chuỗi tải trọng thành số nguyên (Int)
          taiTrongToiDa: int.tryParse(_taiTrongController.text.trim()) ?? 0,
        );

        if (isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); 
        }
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Đăng ký ', style: TextStyle(color: Colors.black87)),
                        TextSpan(text: 'Đối tác', style: TextStyle(color: _primaryRed)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THÔNG TIN CÁ NHÂN',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        _buildLabel('HỌ VÀ TÊN'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('Nguyễn Văn A', Icons.person_outline),
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('SỐ ĐIỆN THOẠI'),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _buildInputDecoration('09xxxxxxxx', Icons.phone_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                            if (value.length != 10) return 'Số điện thoại phải đủ 10 số';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('MẬT KHẨU'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _buildInputDecoration('••••••••', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (value.length < 6) return 'Mật khẩu phải dài ít nhất 6 ký tự';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          'HỒ SƠ & PHƯƠNG TIỆN',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const Divider(),
                        const SizedBox(height: 12),

                        _buildLabel('SỐ CCCD'),
                        TextFormField(
                          controller: _cccdController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _buildInputDecoration('012345678901', Icons.credit_card),
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập số CCCD' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('SỐ GIẤY PHÉP LÁI XE (GPLX)'),
                        TextFormField(
                          controller: _gplxController,
                          decoration: _buildInputDecoration('Nhập mã số GPLX', Icons.badge_outlined),
                          validator: (value) => value!.isEmpty ? 'Vui lòng nhập số GPLX' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('BIỂN SỐ XE'),
                                  TextFormField(
                                    controller: _bienSoXeController,
                                    decoration: _buildInputDecoration('59A-12345', Icons.directions_car_outlined),
                                    validator: (value) => value!.isEmpty ? 'Nhập biển số' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TẢI TRỌNG (KG)'),
                                  TextFormField(
                                    controller: _taiTrongController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: _buildInputDecoration('VD: 50', Icons.monitor_weight_outlined),
                                    validator: (value) => value!.isEmpty ? 'Nhập tải trọng' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('LOẠI PHƯƠNG TIỆN'),
                        DropdownButtonFormField<String>(
                          value: _selectedPhuongTien,
                          decoration: _buildInputDecoration('', Icons.local_shipping_outlined),
                          items: <String>['Xe máy', 'Xe ba gác', 'Xe tải nhỏ', 'Xe bán tải']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPhuongTien = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        // Nút Đăng ký
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Xác nhận Đăng ký',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryRed),
      ),
    );
  }
}