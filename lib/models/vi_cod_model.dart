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