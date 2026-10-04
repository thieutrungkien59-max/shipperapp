enum DeliveryStatus {
  created,
  pendingAssignment,
  assigned,
  driverAccepted,
  driverToPickup,
  arrivedPickup,
  pickedUp,
  inTransit,
  arrivedDropoff,
  completed,
  cancelled,
  failedDelivery,
  returning,
  returned,
  unknown,
}

class DeliveryStatusMapper {
  DeliveryStatusMapper._();

  static DeliveryStatus fromBackend(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'CREATED':
        return DeliveryStatus.created;
      case 'PENDING_ASSIGNMENT':
      case 'PENDING':
      case 'CHOXACNHAN':
        return DeliveryStatus.pendingAssignment;
      case 'ASSIGNED':
      case 'CHOSHIPPERXACNHAN':
        return DeliveryStatus.assigned;
      case 'DRIVER_ACCEPTED':
      case 'DAXACNHAN':
        return DeliveryStatus.driverAccepted;
      case 'DRIVER_TO_PICKUP':
      case 'DANHANDON':
        return DeliveryStatus.driverToPickup;
      case 'ARRIVED_PICKUP':
        return DeliveryStatus.arrivedPickup;
      case 'PICKED_UP':
      case 'DANHANG':
        return DeliveryStatus.pickedUp;
      case 'IN_TRANSIT':
      case 'DANGGIAO':
        return DeliveryStatus.inTransit;
      case 'ARRIVED_DROPOFF':
        return DeliveryStatus.arrivedDropoff;
      case 'COMPLETED':
      case 'DAGIAO':
        return DeliveryStatus.completed;
      case 'CANCELLED':
      case 'DAHUY':
        return DeliveryStatus.cancelled;
      case 'FAILED_DELIVERY':
      case 'GIAOTHATBAI':
        return DeliveryStatus.failedDelivery;
      case 'RETURNING':
      case 'HUYTRAHANG':
        return DeliveryStatus.returning;
      case 'RETURNED':
      case 'DABANGIAO':
        return DeliveryStatus.returned;
      default:
        return DeliveryStatus.unknown;
    }
  }

  static String label(String? backendValue) {
    switch (fromBackend(backendValue)) {
      case DeliveryStatus.created:
        return 'Đã tạo';
      case DeliveryStatus.pendingAssignment:
        return 'Chờ điều phối';
      case DeliveryStatus.assigned:
        return 'Đã gán tài xế';
      case DeliveryStatus.driverAccepted:
        return 'Tài xế đã nhận';
      case DeliveryStatus.driverToPickup:
        return 'Đang đến điểm lấy';
      case DeliveryStatus.arrivedPickup:
        return 'Đã đến điểm lấy';
      case DeliveryStatus.pickedUp:
        return 'Đã lấy hàng';
      case DeliveryStatus.inTransit:
        return 'Đang vận chuyển';
      case DeliveryStatus.arrivedDropoff:
        return 'Đã đến người nhận';
      case DeliveryStatus.completed:
        return 'Hoàn tất';
      case DeliveryStatus.cancelled:
        return 'Đã hủy';
      case DeliveryStatus.failedDelivery:
        return 'Giao thất bại';
      case DeliveryStatus.returning:
        return 'Đang hoàn hàng';
      case DeliveryStatus.returned:
        return 'Đã hoàn hàng';
      case DeliveryStatus.unknown:
        return backendValue?.isNotEmpty == true ? backendValue! : 'Không rõ';
    }
  }

  static bool isDeliveryPhase(String? backendValue) {
    return const {
      DeliveryStatus.pickedUp,
      DeliveryStatus.inTransit,
      DeliveryStatus.arrivedDropoff,
    }.contains(fromBackend(backendValue));
  }
}
