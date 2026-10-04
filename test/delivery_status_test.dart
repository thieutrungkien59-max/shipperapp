import 'package:flutter_test/flutter_test.dart';
import 'package:shipperapp/core/domain/delivery_status.dart';

void main() {
  group('DeliveryStatusMapper', () {
    test('maps V2 and legacy statuses to one domain status', () {
      expect(
        DeliveryStatusMapper.fromBackend('IN_TRANSIT'),
        DeliveryStatus.inTransit,
      );
      expect(
        DeliveryStatusMapper.fromBackend('DangGiao'),
        DeliveryStatus.inTransit,
      );
      expect(
        DeliveryStatusMapper.fromBackend('ChoShipperXacNhan'),
        DeliveryStatus.assigned,
      );
    });

    test('returns Vietnamese labels', () {
      expect(DeliveryStatusMapper.label('DaGiao'), 'Hoàn tất');
      expect(DeliveryStatusMapper.label('GiaoThatBai'), 'Giao thất bại');
    });

    test('detects delivery phase across contracts', () {
      expect(DeliveryStatusMapper.isDeliveryPhase('DangGiao'), isTrue);
      expect(DeliveryStatusMapper.isDeliveryPhase('IN_TRANSIT'), isTrue);
      expect(DeliveryStatusMapper.isDeliveryPhase('DaXacNhan'), isFalse);
    });
  });
}
