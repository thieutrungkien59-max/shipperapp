// File: lib/models/don_hang_model.dart

class DonHangModel {
  final String id;
  final String customerName;
  final String address;
  final String status;

  DonHangModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.status,
  });

  // Dữ liệu giả lập (Mock Data) - Rất dễ thêm, sửa, xóa tại đây
  static List<DonHangModel> mockData = [
    DonHangModel(
      id: 'LR-VN-99283',
      customerName: 'Nguyễn Văn A',
      address: '123 Đường Lê Lợi, Quận 1, TP.HCM',
      status: 'Đang giao',
    ),
    DonHangModel(
      id: 'LR-VN-99284',
      customerName: 'Trần Thị B',
      address: '45 Nguyễn Trãi, Quận 5, TP.HCM',
      status: 'Chờ lấy hàng',
    ),
  ];
}