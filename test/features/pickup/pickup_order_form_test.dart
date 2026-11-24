import 'package:ecotrash/core/services/points_providers.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_notification_service.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_order_form_page.dart';
import 'package:ecotrash/features/pickup/presentation/pickup_page.dart';
import 'package:ecotrash/features/pickup/presentation/providers/pickup_order_providers.dart';
import 'package:ecotrash/features/pickup/data/repositories/shared_preferences_pickup_order_repository.dart';
import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/points_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('creates an order from the stepper and lists it as active', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final notificationService = _RecordingNotificationService();
    final router = GoRouter(
      initialLocation: '/pickup/new',
      routes: [
        GoRoute(
          path: '/pickup/new',
          builder: (context, state) => const PickupOrderFormPage(),
        ),
        GoRoute(
          path: '/pickup',
          builder: (context, state) => const Scaffold(body: PickupPage()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pickupOrderRepositoryProvider.overrideWithValue(
            SharedPreferencesPickupOrderRepository(),
          ),
          pickupNotificationServiceProvider.overrideWithValue(
            notificationService,
          ),
          pointsServiceProvider.overrideWithValue(_NoopPointsService()),
          pickupSimulationIntervalProvider.overrideWith(
            (ref) => const Duration(days: 1),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('id'), Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pickup-waste-plastic')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pickup-weight-plastic')), '3');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-step-next-0')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pickup-address')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('pickup-address')),
      'Jalan Melati nomor 10',
    );

    await tester.ensureVisible(find.byKey(const Key('pickup-step-next-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-step-next-1')).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pickup-select-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-select-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pickup-slot-08')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-slot-08')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pickup-step-next-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-step-next-2')).first);
    await tester.pumpAndSettle();
    expect(find.text('45'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('pickup-submit-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickup-submit-order')));
    await tester.pumpAndSettle();

    expect(find.text('Layanan Penjemputan'), findsOneWidget);
    expect(find.byKey(const Key('pickup-order-list')), findsOneWidget);
    expect(notificationService.remindersScheduled, 1);
    expect(
      (await SharedPreferencesPickupOrderRepository().loadOrders())
          .single
          .status,
      PickupOrderStatus.waitingConfirmation,
    );
  });
}

class _RecordingNotificationService implements PickupNotificationService {
  int remindersScheduled = 0;

  @override
  Future<void> cancelPickupReminder(String orderId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedulePickupReminder(PickupOrder order) async {
    remindersScheduled++;
  }

  @override
  Future<void> showStatusChange(
    PickupOrder order,
    PickupOrderStatus status,
  ) async {}
}

class _NoopPointsService implements PointsService {
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
