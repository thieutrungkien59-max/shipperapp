import 'package:flutter_test/flutter_test.dart';
import 'package:shipperapp/models/don_hang_model.dart';
import 'package:shipperapp/models/shipping_quote_model.dart';
import 'package:shipperapp/models/vi_cod_model.dart';

void main() {
  test('DonHangModel accepts legacy and V2-shaped fields', () {
    final order = DonHangModel.fromJson({
      'id': 'order-1',
      'senderName': 'Người gửi',
      'receiverName': 'Người nhận',
      'pickupAddress': 'Điểm lấy',
      'deliveryAddress': 'Điểm giao',
      'weight': '2.5',
      'codAmount': 150000,
      'shippingFee': 30000,
      'status': 'IN_TRANSIT',
    });

    expect(order.maDh, 'order-1');
    expect(order.khoiLuong, 2.5);
    expect(order.tienCod, 150000);
  });

  test('ShippingQuoteModel parses numeric strings and route points', () {
    final quote = ShippingQuoteModel.fromJson({
      'distanceKm': '7.5',
      'durationMinutes': 18,
      'shippingFee': 32000,
      'routePoints': [
        {'latitude': 10.77, 'longitude': 106.69},
      ],
    });

    expect(quote.distanceKm, 7.5);
    expect(quote.durationMinutes, 18);
    expect(quote.shippingFee, 32000);
    expect(quote.routePoints, hasLength(1));
  });

  test('ViCodModel parses integer and string money values', () {
    final wallet = ViCodModel.fromJson({
      'maVi': 'wallet-1',
      'maSp': 'driver-1',
      'soDuHienTai': '450000',
      'hanMucToiDa': 1000000,
      'trangThai': 'AnToan',
    });

    expect(wallet.soDuHienTai, 450000);
    expect(wallet.hanMucToiDa, 1000000);
  });
}
