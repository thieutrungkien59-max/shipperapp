import 'package:flutter/material.dart';

class CodOrderItem {
  final String code;
  final String customerName;
  final String amount;

  const CodOrderItem({
    required this.code,
    required this.customerName,
    required this.amount,
  });
}

const _mockCodOrders = [
  CodOrderItem(code: 'LR-8472-A', customerName: 'Nguyễn Văn A', amount: '450,000'),
  CodOrderItem(code: 'LR-9102-B', customerName: 'Trần Thị B', amount: '1,200,000'),
  CodOrderItem(code: 'LR-3341-C', customerName: 'Lê Văn C', amount: '800,000'),
  CodOrderItem(code: 'LR-5589-D', customerName: 'Phạm Thị D', amount: '1,000,000'),
];

class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  static const Color _primaryRed = Color(0xFFE51D35);
  static const Color _orange = Color(0xFFD9720B);

  int _selectedMethod = 1;

  final _amountController = TextEditingController(text: '3,450,000');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    debugPrint('Phương thức: $_selectedMethod, Số tiền: ${_amountController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          const SizedBox(height: 24),
          const Text(
            'Danh sách đơn hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildOrdersList(),
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
    );
  }

  Widget _buildTotalCard() {
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
          const Text(
            '3,450,000',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _orange,
            ),
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
              children: const [
                Icon(Icons.access_time, size: 14, color: _orange),
                SizedBox(width: 6),
                Text(
                  'Hạn nộp: 10:00 sáng mai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(_mockCodOrders.length, (index) {
          final order = _mockCodOrders[index];
          final isLast = index == _mockCodOrders.length - 1;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  order.amount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _orange,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Color(0xFF2E9E5B), size: 20),
              ],
            ),
          );
        }),
      ),
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