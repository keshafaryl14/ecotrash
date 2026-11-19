import 'dart:async';

import 'package:ecotrash/core/services/points_service.dart';
import 'package:ecotrash/core/services/shared_preferences_points_service.dart';
import 'package:ecotrash/features/pickup/data/repositories/shared_preferences_pickup_order_repository.dart';
import 'package:ecotrash/features/pickup/data/services/local_pickup_notification_service.dart';
import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/repositories/pickup_order_repository.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pickupOrderRepositoryProvider = Provider<PickupOrderRepository>((ref) {
  return SharedPreferencesPickupOrderRepository();
});

final pickupNotificationServiceProvider = Provider<PickupNotificationService>((
  ref,
) {
  return LocalPickupNotificationService();
});

final pointsServiceProvider = Provider<PointsService>((ref) {
  return SharedPreferencesPointsService();
});

final pickupSimulationIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 30);
});

final pickupOrderControllerProvider =
    AsyncNotifierProvider<PickupOrderController, List<PickupOrder>>(
      PickupOrderController.new,
    );

class PickupOrderController extends AsyncNotifier<List<PickupOrder>> {
  Timer? _statusTimer;
  bool _isAdvancing = false;

  @override
  Future<List<PickupOrder>> build() async {
    _statusTimer?.cancel();
    ref.onDispose(() => _statusTimer?.cancel());
    final orders = await ref.read(pickupOrderRepositoryProvider).loadOrders();
    for (final order in orders.where(
      (item) => item.status == PickupOrderStatus.completed,
    )) {
      await ref
          .read(pointsServiceProvider)
          .awardPickupCompletion(
            orderId: order.id,
            points: order.estimatedPoints,
          );
    }
    _statusTimer = Timer.periodic(
      ref.read(pickupSimulationIntervalProvider),
      (_) => unawaited(_advanceOrderStatuses()),
    );
    return orders;
  }

  Future<String?> createOrder(PickupOrder order) async {
    final repository = ref.read(pickupOrderRepositoryProvider);
    await repository.saveOrder(order);
    await _reloadOrders();

    try {
      final notifications = ref.read(pickupNotificationServiceProvider);
      final allowed = await notifications.requestPermission();
      if (!allowed) {
        return 'Pesanan tersimpan, tetapi izin notifikasi belum diberikan.';
      }
      await notifications.schedulePickupReminder(order);
      await notifications.showStatusChange(
        order,
        PickupOrderStatus.waitingConfirmation,
      );
      return null;
    } catch (error) {
      return 'Pesanan tersimpan, tetapi notifikasi gagal disiapkan: $error';
    }
  }

  Future<String?> cancelOrder(String orderId) async {
    final order = await _findOrder(orderId);
    if (!order.status.canBeCancelled) {
      throw const PickupOrderException(
        'Pesanan tidak dapat dibatalkan setelah kurir menuju lokasi.',
      );
    }
    final cancelled = order.copyWith(status: PickupOrderStatus.cancelled);
    await ref.read(pickupOrderRepositoryProvider).updateOrder(cancelled);
    await _reloadOrders();
    try {
      final notifications = ref.read(pickupNotificationServiceProvider);
      await notifications.cancelPickupReminder(orderId);
      await notifications.showStatusChange(
        cancelled,
        PickupOrderStatus.cancelled,
      );
      return null;
    } catch (error) {
      return 'Pesanan dibatalkan, tetapi notifikasi gagal diperbarui: $error';
    }
  }

  Future<void> advanceOrderStatus(String orderId) async {
    final order = await _findOrder(orderId);
    final nextStatus = switch (order.status) {
      PickupOrderStatus.waitingConfirmation => PickupOrderStatus.confirmed,
      PickupOrderStatus.confirmed => PickupOrderStatus.courierEnRoute,
      PickupOrderStatus.courierEnRoute => PickupOrderStatus.completed,
      PickupOrderStatus.completed || PickupOrderStatus.cancelled => null,
    };
    if (nextStatus == null) {
      return;
    }
    final updated = order.copyWith(status: nextStatus);
    await ref.read(pickupOrderRepositoryProvider).updateOrder(updated);
    await _reloadOrders();

    if (nextStatus == PickupOrderStatus.completed) {
      await ref
          .read(pointsServiceProvider)
          .awardPickupCompletion(
            orderId: updated.id,
            points: updated.estimatedPoints,
          );
    }
    final notifications = ref.read(pickupNotificationServiceProvider);
    await notifications.showStatusChange(updated, nextStatus);
    if (nextStatus == PickupOrderStatus.completed) {
      await notifications.cancelPickupReminder(updated.id);
    }
  }

  Future<void> _advanceOrderStatuses() async {
    if (_isAdvancing || !state.hasValue) {
      return;
    }
    _isAdvancing = true;
    try {
      final activeOrders = state.requireValue
          .where((order) => order.status.isActive)
          .toList();
      for (final order in activeOrders) {
        await advanceOrderStatus(order.id);
      }
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _isAdvancing = false;
    }
  }

  Future<PickupOrder> _findOrder(String orderId) async {
    final orders =
        state.value ??
        await ref.read(pickupOrderRepositoryProvider).loadOrders();
    for (final order in orders) {
      if (order.id == orderId) {
        return order;
      }
    }
    throw const PickupOrderException('Pesanan tidak ditemukan.');
  }

  Future<void> _reloadOrders() async {
    state = AsyncData(
      await ref.read(pickupOrderRepositoryProvider).loadOrders(),
    );
  }
}
