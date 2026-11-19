import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';

abstract interface class PickupNotificationService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedulePickupReminder(PickupOrder order);

  Future<void> showStatusChange(PickupOrder order, PickupOrderStatus status);

  Future<void> cancelPickupReminder(String orderId);
}
