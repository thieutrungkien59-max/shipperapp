import 'package:flutter/material.dart';
// Thêm import HomeScreen dựa trên cấu trúc thư mục
import '../../home/screens/home_screen.dart';

/// Màn hình đăng nhập - LogiDriver
/// Theo thiết kế: nền be nhạt, card trắng bo góc chứa form đăng nhập
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // TODO: chuyển các màu này sang core/constants/app_colors.dart để dùng chung toàn app
  static const Color primaryRed = Color(0xFFE63946);
  static const Color backgroundBeige = Color(0xFFFBF3EE);
  static const Color textGrey = Color(0xFF8A8A8A);
  static const Color borderGrey = Color(0xFFE0E0E0);

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // TODO: gọi ApiService/FirebaseAuthService để xử lý đăng nhập thật
    debugPrint('Số điện thoại: ${_phoneController.text}');
    debugPrint('Mật khẩu: ${_passwordController.text}');

    // Logic chuyển tạm sang trang Home, sẽ bổ sung validate database sau
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _handleOtpLogin() {
    // TODO: điều hướng sang otp_screen.dart (dùng app_routes.dart)
  }

  void _handleForgotPassword() {
    // TODO: điều hướng sang màn hình quên mật khẩu (chưa có trong cây thư mục hiện tại)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Logo
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Roboto',
                  ),
                  children: [
                    TextSpan(
                      text: 'Logi',
                      style: TextStyle(color: Colors.black87),
                    ),
                    TextSpan(
                      text: 'Driver',
                      style: TextStyle(color: primaryRed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Card chứa form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SỐ ĐIỆN THOẠI'),
                    const SizedBox(height: 8),
                    _buildPhoneField(),
                    const SizedBox(height: 20),
                    _buildLabel('MẬT KHẨU'),
                    const SizedBox(height: 8),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(),
                    const SizedBox(height: 18),
                    _buildDivider(),
                    const SizedBox(height: 18),
                    _buildOtpButton(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.phone_outlined, color: Colors.black54),
          hintText: '09xxxxxxxx',
          hintStyle: TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.black45,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Đăng nhập',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: borderGrey)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('hoặc', style: TextStyle(color: textGrey, fontSize: 13)),
        ),
        Expanded(child: Divider(color: borderGrey)),
      ],
    );
  }

  Widget _buildOtpButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleOtpLogin,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: borderGrey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Đăng nhập bằng OTP',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}