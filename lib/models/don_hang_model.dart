class DonHangModel {
  final String maDh;
  final String maKh;
  final String? maSp; // Có thể null nếu đơn chưa được gán cho Shipper nào
  final String tenNguoiNhan;
  final String sdtNguoiNhan;
  final String diaChiLay;
  final String diaChiGiao;
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
    required this.diaChiLay,
    required this.diaChiGiao,
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
      diaChiLay: (json['diaChiLay'] ?? json['diemLayHang'])?.toString() ?? '',
      diaChiGiao: (json['diaChiGiao'] ?? json['diemGiaoHang'])?.toString() ?? '',
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