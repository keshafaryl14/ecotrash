import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/repositories/pickup_order_repository.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_notification_service.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_order_detail_page.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('cancels an eligible order after confirmation', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakePickupOrderRepository([_activeOrder()]);
    final router = GoRouter(
      initialLocation: '/pickup/detail/order-1',
      routes: [
        GoRoute(
          path: '/pickup/detail/:id',
          builder: (context, state) =>
              PickupOrderDetailPage(orderId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pickupOrderRepositoryProvider.overrideWithValue(repository),
          pickupNotificationServiceProvider.overrideWithValue(
            _FakePickupNotificationService(),
          ),
          pointsServiceProvider.overrideWithValue(_FakePointsService()),
          pickupSimulationIntervalProvider.overrideWith(
            (ref) => const Duration(days: 1),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('pickup-detail-status'))).data,
      'Menunggu konfirmasi',
    );

    await tester.tap(find.byKey(const Key('pickup-cancel-order')));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pesanan?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pickup-cancel-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('pickup-detail-status'))).data,
      'Dibatalkan',
    );
    expect(repository.orders.single.status, PickupOrderStatus.cancelled);
    expect(find.byKey(const Key('pickup-cancel-order')), findsNothing);
  });

  testWidgets('does not allow cancellation after courier departure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final order = _activeOrder().copyWith(
      status: PickupOrderStatus.courierEnRoute,
    );
    final router = GoRouter(
      initialLocation: '/pickup/detail/order-1',
      routes: [
        GoRoute(
          path: '/pickup/detail/:id',
          builder: (context, state) =>
              PickupOrderDetailPage(orderId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pickupOrderRepositoryProvider.overrideWithValue(
            _FakePickupOrderRepository([order]),
          ),
          pickupNotificationServiceProvider.overrideWithValue(
            _FakePickupNotificationService(),
          ),
          pointsServiceProvider.overrideWithValue(_FakePointsService()),
          pickupSimulationIntervalProvider.overrideWith(
            (ref) => const Duration(days: 1),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('pickup-detail-status'))).data,
      'Kurir menuju lokasi',
    );
    expect(find.byKey(const Key('pickup-cancel-order')), findsNothing);
    expect(
      find.byKey(const Key('pickup-cancel-locked-message')),
      findsOneWidget,
    );
  });
}

PickupOrder _activeOrder() {
  final now = DateTime.now();
  return PickupOrder(
    id: 'order-1',
    wasteWeightsKg: const {PickupWasteType.plastic: 3},
    address: 'Jalan Melati nomor 10',
    courierNote: '',
    pickupAt: now.add(const Duration(days: 1)),
    timeSlot: '08.00-10.00',
    createdAt: now,
    status: PickupOrderStatus.waitingConfirmation,
  );
}

class _FakePickupOrderRepository implements PickupOrderRepository {
  _FakePickupOrderRepository(this.orders);

  final List<PickupOrder> orders;

  @override
  Future<List<PickupOrder>> loadOrders() async => List.of(orders);

  @override
  Future<void> saveOrder(PickupOrder order) async => orders.insert(0, order);

  @override
  Future<void> updateOrder(PickupOrder order) async {
    final index = orders.indexWhere((item) => item.id == order.id);
    if (index < 0) {
      throw const PickupOrderException('Pesanan tidak ditemukan.');
    }
    orders[index] = order;
  }
}

class _FakePickupNotificationService implements PickupNotificationService {
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

class _FakePointsService implements PointsService {
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
  }) async {}
}
