class ViCodModel {
  final String maVi;
  final String maSp;
  final double soDuHienTai;
  final double hanMucToiDa;
  final String trangThai; // ví dụ: "AnToan", "CanhBao", "VuotHanMuc"
  final DateTime? caLamViec;

  ViCodModel({
    required this.maVi,
    required this.maSp,
    required this.soDuHienTai,
    required this.hanMucToiDa,
    required this.trangThai,
    this.caLamViec,
  });

  // Hàm chuyển đổi số an toàn: API có thể trả về int hoặc double tùy giá trị
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory ViCodModel.fromJson(Map<String, dynamic> json) {
    return ViCodModel(
      maVi: json['maVi']?.toString() ?? '',
      maSp: json['maSp']?.toString() ?? '',
      soDuHienTai: _parseDouble(json['soDuHienTai']),
      hanMucToiDa: _parseDouble(json['hanMucToiDa']),
      trangThai: json['trangThai']?.toString() ?? '',
      caLamViec: json['caLamViec'] != null
          ? DateTime.tryParse(json['caLamViec'].toString())
          : null,
    );
  }
}

// Model cho 1 phiếu nộp COD (kết quả trả về từ tao-phieu / danh-sach-phieu-cho-duyet)
// Dùng để kiểm tra shipper có phiếu nào đang "ChoDuyet" chưa, tránh tạo phiếu trùng.
class PhieuDoiSoatModel {
  final String maDs;
  final String maSp;
  final double tongTienNop;
  final String trangThai; // "ChoDuyet", "DaDuyet"...
  final DateTime? ngayDoiSoat;

  PhieuDoiSoatModel({
    required this.maDs,
    required this.maSp,
    required this.tongTienNop,
    required this.trangThai,
    this.ngayDoiSoat,
  });

  factory PhieuDoiSoatModel.fromJson(Map<String, dynamic> json) {
    return PhieuDoiSoatModel(
      maDs: json['maDs']?.toString() ?? '',
      maSp: json['maSp']?.toString() ?? '',
      tongTienNop: ViCodModel._parseDouble(json['tongTienNop']),
      trangThai: json['trangThai']?.toString() ?? '',
      ngayDoiSoat: json['ngayDoiSoat'] != null
          ? DateTime.tryParse(json['ngayDoiSoat'].toString())
          : null,
    );
  }
}