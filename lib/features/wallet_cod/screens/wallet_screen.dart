import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../core/repositories/vi_cod_repository.dart';
import '../../../models/vi_cod_model.dart';

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  static const Color _primaryRed = Color(0xFFE51D35);
  static const Color _orange = Color(0xFFD9720B);

  int _selectedMethod = 1;

  final _amountController = TextEditingController();

  // ---> Gọi API lấy thông tin Ví COD <---
  late ApiServices _apiService;
  late ViCodRepository _viCodRepository;
  Future<ViCodModel>? _futureViCod;
  Future<int>? _futureCanhBaoCount;

  @override
  void initState() {
    super.initState();
    _apiService = ApiServices();
    _viCodRepository = ViCodRepository(_apiService);
    _loadViCod();
    _loadCanhBaoCount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadViCod() async {
    final prefs = await SharedPreferences.getInstance();
    final maSp = prefs.getString('maSp');

    if (maSp == null || maSp.isEmpty) {
      setState(() {
        _futureViCod = Future.error('Không tìm thấy mã Shipper. Vui lòng đăng nhập lại.');
      });
      return;
    }

    setState(() {
      _futureViCod = _viCodRepository.getViCodByShipper(maSp);
    });

    // Điền sẵn số tiền đã nộp = số dư hiện tại (nhưng người dùng vẫn sửa được)
    try {
      final vi = await _futureViCod!;
      if (mounted) {
        _amountController.text = _formatCurrency(vi.soDuHienTai);
      }
    } catch (_) {
      // Lỗi đã được FutureBuilder xử lý hiển thị, không cần làm gì thêm ở đây
    }
  }

  Future<void> _loadCanhBaoCount() async {
    setState(() {
      _futureCanhBaoCount = _viCodRepository.getCanhBaoCodCount();
    });
  }

  void _handleConfirm() {
    // TODO: gọi API xác nhận đã nộp COD khi backend có endpoint tương ứng
    debugPrint('Phương thức: $_selectedMethod, Số tiền: ${_amountController.text}');
  }

  // Định dạng số kiểu 1.234.567 (không dùng package intl vì project chưa có sẵn)
  String _formatCurrency(double value) {
    final intValue = value.round();
    final str = intValue.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // Nhãn + màu hiển thị theo trạng thái ví
  // LƯU Ý: chỉ chắc chắn giá trị "AnToan" theo response mẫu bạn gửi.
  // Các giá trị khác (CanhBao, VuotHanMuc...) là dự đoán hợp lý - kiểm tra lại
  // với backend/Swagger để chỉnh đúng tên enum thật nếu khác.
  String _trangThaiLabel(String trangThai) {
    switch (trangThai) {
      case 'AnToan':
        return 'An toàn';
      case 'CanhBao':
        return 'Cảnh báo';
      case 'VuotHanMuc':
        return 'Vượt hạn mức';
      default:
        return trangThai;
    }
  }

  Color _trangThaiColor(String trangThai) {
    switch (trangThai) {
      case 'AnToan':
        return const Color(0xFF2E9E5B);
      case 'CanhBao':
        return _orange;
      case 'VuotHanMuc':
        return _primaryRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadViCod(), _loadCanhBaoCount()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đối soát COD cuối ca',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildTotalCard(),
            const SizedBox(height: 12),
            _buildCanhBaoBanner(),
            const SizedBox(height: 24),
            const Text(
              'Phương thức nộp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildCashOption(),
            const SizedBox(height: 12),
            _buildBankTransferOption(),
            const SizedBox(height: 24),
            const Text(
              'SỐ TIỀN ĐÃ NỘP (VNĐ)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildAmountField(),
            const SizedBox(height: 6),
            const Text(
              'Có thể nộp toàn bộ hoặc một phần',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 20),
            _buildConfirmButton(),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Biên lai sẽ được gửi qua Email/SMS sau khi Quản lý xác nhận',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return FutureBuilder<ViCodModel>(
      future: _futureViCod,
      builder: (context, snapshot) {
        // Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE4DE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: _orange),
            ),
          );
        }

        // Lỗi (vd: mất mạng, chưa đăng nhập, backend lỗi)
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE4DE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  snapshot.error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _primaryRed, fontSize: 13),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _loadViCod,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        // Thành công
        final vi = snapshot.data;
        if (vi == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBE4DE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Tổng COD đang giữ (VNĐ)',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(vi.soDuHienTai),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hạn mức tối đa: ${_formatCurrency(vi.hanMucToiDa)}đ',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: _trangThaiColor(vi.trangThai)),
                    const SizedBox(width: 6),
                    Text(
                      _trangThaiLabel(vi.trangThai),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _trangThaiColor(vi.trangThai),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanhBaoBanner() {
    return FutureBuilder<int>(
      future: _futureCanhBaoCount,
      builder: (context, snapshot) {
        // Đang tải hoặc lỗi -> không hiện gì cả, tránh làm rối giao diện
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final count = snapshot.data ?? 0;
        final hasWarning = count > 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: hasWarning ? const Color(0xFFFDF0E0) : const Color(0xFFE4F5EA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                hasWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                size: 18,
                color: hasWarning ? _orange : const Color(0xFF2E9E5B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasWarning
                      ? 'Có $count cảnh báo COD cần chú ý'
                      : 'Không có cảnh báo COD nào',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasWarning ? _orange : const Color(0xFF2E9E5B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashOption() {
    final isSelected = _selectedMethod == 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryRed : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _primaryRed : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Tiền mặt tại kho', style: TextStyle(fontSize: 15)),
            ),
            Icon(Icons.storefront_outlined, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferOption() {
    final isSelected = _selectedMethod == 1;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = 1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryRed : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? _primaryRed : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chuyển khoản ngân hàng (VietQR)',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Icon(Icons.account_balance_outlined, color: Colors.grey.shade600),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              _buildQrPlaceholder(),
              const SizedBox(height: 14),
              const Text(
                'NGÂN HÀNG TECHCOMBANK',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '1903 4567 890 011',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'CTCP LogiRoute - CN HCM',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQrPlaceholder() {
    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ĐỐI SOÁT & NỘP COD CUỐI CA',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          Icon(Icons.qr_code_2, size: 90, color: Colors.grey.shade800),
          const SizedBox(height: 8),
          const Text(
            'Quét mã để xác nhận thanh toán COD',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 8, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'XÁC NHẬN ĐÃ NỘP',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}