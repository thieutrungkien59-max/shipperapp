class DonHangModel {
  final String maDh;
  final String maKh;
  final String? maSp; // Có thể null nếu đơn chưa được gán cho Shipper nào
  final String tenNguoiNhan;
  final String sdtNguoiNhan;
  final String sdtNguoiGui; // SĐT liên hệ tại điểm lấy hàng (người gửi)
  final String diaChiLay;
  final String diaChiGiao;
  // Toạ độ thật của điểm lấy/giao hàng — null nếu backend/đơn cũ chưa có dữ liệu
  // này, khi đó Shipper app sẽ tự vẽ tuyến đường mô phỏng thay thế (xem RouteSimulator).
  final double? viDoLay;
  final double? kinhDoLay;
  final double? viDoGiao;
  final double? kinhDoGiao;
  // Quãng đường/thời gian tổng của ĐƠN HÀNG (điểm lấy -> điểm giao), do backend tính sẵn
  // khi tạo đơn — khác với tuyến đường "Chỉ đường" (từ vị trí Shipper hiện tại -> điểm đến),
  // vốn được tính riêng qua OrderRepository.calculateShippingRoute().
  final double? quangDuongKm;
  final int? duKienGiaoPhut;
  final double khoiLuong; // Đơn vị: kg - dùng để so sánh với tải trọng tối đa của Shipper
  final String? kichThuoc;
  final double tienCod;
  final double phiGiaoHang;
  final String trangThai;
  final int soLanGiaoThatBai;
  final DateTime? ngayTao;

  DonHangModel({
    required this.maDh,
    required this.maKh,
    this.maSp,
    required this.tenNguoiNhan,
    required this.sdtNguoiNhan,
    this.sdtNguoiGui = '',
    required this.diaChiLay,
    required this.diaChiGiao,
    this.viDoLay,
    this.kinhDoLay,
    this.viDoGiao,
    this.kinhDoGiao,
    this.quangDuongKm,
    this.duKienGiaoPhut,
    required this.khoiLuong,
    this.kichThuoc,
    required this.tienCod,
    required this.phiGiaoHang,
    required this.trangThai,
    required this.soLanGiaoThatBai,
    this.ngayTao,
  });

  // Hàm chuyển đổi số an toàn: API có thể trả về int hoặc double tùy giá trị
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // Giống _parseDouble nhưng giữ null khi API chưa có dữ liệu (khác với giá trị 0.0 thật)
  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // LƯU Ý: Có 2 API trả về đơn hàng với tên field hơi khác nhau:
  // - GET /api/DonHang/shipper/{maSp}        -> maDh, diaChiLay, diaChiGiao, khoiLuong...
  // - GET /api/DonHang/danh-sach-cho-nhan     -> id/maDon, diemLayHang, diemGiaoHang, trongLuong...
  // fromJson dưới đây đọc được cả 2 kiểu bằng cách thử lần lượt các tên field khả dĩ.
  factory DonHangModel.fromJson(Map<String, dynamic> json) {
    return DonHangModel(
      maDh: (json['maDh'] ?? json['maDon'] ?? json['id'])?.toString() ?? '',
      maKh: json['maKh']?.toString() ?? '',
      maSp: json['maSp']?.toString(),
      tenNguoiNhan: json['tenNguoiNhan']?.toString() ?? '',
      sdtNguoiNhan: (json['sdtNguoiNhan'] ?? json['lienHeGiaoHang'])?.toString() ?? '',
      // Backend hiện có thể trả field này dưới nhiều tên khác nhau tuỳ API;
      // thử lần lượt các khả năng, để trống nếu API chưa có dữ liệu này.
      sdtNguoiGui: (json['sdtNguoiGui'] ?? json['lienHeLayHang'] ?? json['sdtNguoiGoi'])?.toString() ?? '',
      diaChiLay: (json['diaChiLay'] ?? json['diemLayHang'])?.toString() ?? '',
      diaChiGiao: (json['diaChiGiao'] ?? json['diemGiaoHang'])?.toString() ?? '',
      viDoLay: _parseNullableDouble(json['viDoLay']),
      kinhDoLay: _parseNullableDouble(json['kinhDoLay']),
      viDoGiao: _parseNullableDouble(json['viDoGiao']),
      kinhDoGiao: _parseNullableDouble(json['kinhDoGiao']),
      quangDuongKm: _parseNullableDouble(json['quangDuongKm']),
      duKienGiaoPhut: json['duKienGiaoPhut'] is int
          ? json['duKienGiaoPhut']
          : int.tryParse('${json['duKienGiaoPhut'] ?? ''}'),
      khoiLuong: _parseDouble(json['khoiLuong'] ?? json['trongLuong']),
      kichThuoc: json['kichThuoc']?.toString(),
      tienCod: _parseDouble(json['tienCod']),
      phiGiaoHang: _parseDouble(json['phiGiaoHang']),
      trangThai: json['trangThai']?.toString() ?? '',
      soLanGiaoThatBai: (json['soLanGiaoThatBai'] is int)
          ? json['soLanGiaoThatBai']
          : int.tryParse('${json['soLanGiaoThatBai'] ?? 0}') ?? 0,
      ngayTao: json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) : null,
    );
  }
}