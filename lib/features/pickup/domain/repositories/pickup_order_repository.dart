import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';

abstract interface class PickupOrderRepository {
  Future<List<PickupOrder>> loadOrders();

  Future<void> saveOrder(PickupOrder order);

  Future<void> updateOrder(PickupOrder order);
}

class PickupOrderException implements Exception {
  const PickupOrderException(this.message);

  final String message;

  @override
  String toString() => message;
}
