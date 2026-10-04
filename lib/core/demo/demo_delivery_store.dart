import '../../models/don_hang_model.dart';
import '../../models/vi_cod_model.dart';

class DemoDeliveryStore {
  DemoDeliveryStore._();

  static final DemoDeliveryStore instance = DemoDeliveryStore._();

  String driverId = 'DEMO-DRIVER-01';
  bool isOnline = false;
  String status = 'ChoShipperXacNhan';

  DonHangModel get order => DonHangModel(
    maDh: 'DEMO-ORDER-001',
    maKh: 'DEMO-SENDER-01',
    maSp: status == 'ChoShipperXacNhan' ? null : driverId,
    tenNguoiNhan: 'Nguyễn Minh Anh',
    sdtNguoiNhan: '0900000002',
    sdtNguoiGui: '0900000001',
    diaChiLay: '72 Nguyễn Huệ, Quận 1, TP.HCM',
    diaChiGiao: '208 Nguyễn Hữu Cảnh, Bình Thạnh, TP.HCM',
    viDoLay: 10.7731,
    kinhDoLay: 106.7043,
    viDoGiao: 10.7951,
    kinhDoGiao: 106.7218,
    quangDuongKm: 5.8,
    duKienGiaoPhut: 24,
    khoiLuong: 2.5,
    kichThuoc: '35 x 25 x 20 cm',
    tienCod: 350000,
    phiGiaoHang: 32000,
    trangThai: status,
    soLanGiaoThatBai: 0,
    ngayTao: DateTime.now(),
  );

  List<DonHangModel> get availableOrders {
    return status == 'ChoXacNhan' ? [order] : const [];
  }

  List<DonHangModel> get assignedOrders {
    return status == 'ChoShipperXacNhan' ? [order] : const [];
  }

  List<DonHangModel> get driverOrders {
    return status == 'ChoXacNhan' || status == 'ChoShipperXacNhan'
        ? const []
        : [order];
  }

  void accept() => status = 'DaXacNhan';

  void reject() => status = 'ChoXacNhan';

  void updateStatus(String next) => status = next;

  void reset() {
    isOnline = false;
    status = 'ChoShipperXacNhan';
  }

  ViCodModel get wallet => ViCodModel(
    maVi: 'DEMO-WALLET-01',
    maSp: driverId,
    soDuHienTai: status == 'DaGiao' ? 350000 : 0,
    hanMucToiDa: 2000000,
    trangThai: 'AnToan',
    caLamViec: DateTime.now(),
  );
}
