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

  // Hàm chuyển đổi dữ liệu JSON từ API thành đối tượng DonHangModel
  factory DonHangModel.fromJson(Map<String, dynamic> json) {
    return DonHangModel(
      // Sử dụng cú pháp ?? '' để gán giá trị rỗng nếu API không trả về trường này, giúp tránh lỗi null
      id: json['id']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}