import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/repositories/pickup_order_repository.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_notification_service.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';

import '../../helpers/points_service_test_adapter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulates status progression and awards completion points', () async {
    final repository = _MemoryOrderRepository([_waitingOrder()]);
    final points = _RecordingPointsService();
    final container = ProviderContainer(
      overrides: [
        pickupOrderRepositoryProvider.overrideWithValue(repository),
        pickupNotificationServiceProvider.overrideWithValue(
          _SilentNotificationService(),
        ),
        pointsServiceProvider.overrideWithValue(points),
        pickupSimulationIntervalProvider.overrideWith(
          (ref) => const Duration(days: 1),
        ),
      ],
    );
    final subscription = container.listen(
      pickupOrderControllerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);

    await container.read(pickupOrderControllerProvider.future);
    final controller = container.read(pickupOrderControllerProvider.notifier);

    await controller.advanceOrderStatus('simulated-order');
    expect(
      container.read(pickupOrderControllerProvider).requireValue.single.status,
      PickupOrderStatus.confirmed,
    );
    await controller.advanceOrderStatus('simulated-order');
    expect(
      container.read(pickupOrderControllerProvider).requireValue.single.status,
      PickupOrderStatus.courierEnRoute,
    );
    await expectLater(
      controller.cancelOrder('simulated-order'),
      throwsA(isA<PickupOrderException>()),
    );
    await controller.advanceOrderStatus('simulated-order');

    expect(
      container.read(pickupOrderControllerProvider).requireValue.single.status,
      PickupOrderStatus.completed,
    );
    expect(points.awards, [('simulated-order', 30)]);
  });
}

PickupOrder _waitingOrder() {
  final now = DateTime.now();
  return PickupOrder(
    id: 'simulated-order',
    wasteWeightsKg: const {PickupWasteType.plastic: 3},
    address: 'Jalan Melati nomor 10',
    courierNote: '',
    pickupAt: now.add(const Duration(days: 1)),
    timeSlot: '08.00-10.00',
    createdAt: now,
    status: PickupOrderStatus.waitingConfirmation,
  );
}

class _MemoryOrderRepository implements PickupOrderRepository {
  _MemoryOrderRepository(this.orders);

  final List<PickupOrder> orders;

  @override
  Future<List<PickupOrder>> loadOrders() async => List.of(orders);

  @override
  Future<void> saveOrder(PickupOrder order) async => orders.insert(0, order);

  @override
  Future<void> updateOrder(PickupOrder order) async {
    final index = orders.indexWhere((item) => item.id == order.id);
    if (index == -1) {
      throw const PickupOrderException('Pesanan tidak ditemukan.');
    }
    orders[index] = order;
  }
}

class _SilentNotificationService implements PickupNotificationService {
  @override
  Future<void> cancelPickupReminder(String orderId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedulePickupReminder(PickupOrder order) async {}

  @override
  Future<void> showStatusChange(
    PickupOrder order,
    PickupOrderStatus status,
  ) async {}
}

class _RecordingPointsService extends PointsServiceTestAdapter {
  final List<(String, int)> awards = [];

  @override
  Future<int> getBalance() async => 0;

  @override
  Future<int> getLifetimePoints() async => 0;

  @override
  Future<List<PointsTransaction>> getTransactions() async => [];

  @override
  Future<void> addPoints({
    required int points,
    required PointsSource source,
    required String description,
    String? referenceId,
  }) async {}

  @override
  Future<void> redeemPoints({
    required int points,
    required String description,
    required String referenceId,
  }) async {}

  @override
  Future<void> awardPickupCompletion({
    required String orderId,
    required int points,
    double totalWeightKg = 0,
  }) async {
    awards.add((orderId, points));
  }
}
