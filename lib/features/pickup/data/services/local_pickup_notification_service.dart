import 'package:ecotrash/features/pickup/domain/entities/pickup_order.dart';
import 'package:ecotrash/features/pickup/domain/services/pickup_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class LocalPickupNotificationService implements PickupNotificationService {
  LocalPickupNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'pickup_updates';
  static const _channelName = 'Pembaruan Penjemputan';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw const PickupNotificationException(
        'Notifikasi lokal tidak dapat diinisialisasi.',
      );
    }
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  @override
  Future<void> schedulePickupReminder(PickupOrder order) async {
    await initialize();
    final now = DateTime.now();
    if (!order.pickupAt.isAfter(now)) {
      return;
    }

    final oneHourBefore = order.pickupAt.subtract(const Duration(hours: 1));
    final reminderAt = oneHourBefore.isAfter(now)
        ? oneHourBefore
        : now.add(const Duration(minutes: 1));
    await _plugin.zonedSchedule(
      id: _notificationId(order.id),
      title: 'Pengingat penjemputan EcoTrash',
      body:
          'Jadwal ${order.timeSlot} sudah dekat. Siapkan '
          '${order.totalWeightKg.toStringAsFixed(1)} kg sampah daur ulang.',
      scheduledDate: timezone.TZDateTime.from(reminderAt, timezone.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Pengingat dan status layanan penjemputan.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: order.id,
    );
  }

  @override
  Future<void> showStatusChange(
    PickupOrder order,
    PickupOrderStatus status,
  ) async {
    await initialize();
    await _plugin.show(
      id: _notificationId(order.id) + status.index + 1,
      title: 'Status penjemputan diperbarui',
      body: 'Pesanan ${order.id}: ${status.label}.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Pengingat dan status layanan penjemputan.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: order.id,
    );
  }

  @override
  Future<void> cancelPickupReminder(String orderId) async {
    await initialize();
    await _plugin.cancel(id: _notificationId(orderId));
  }

  int _notificationId(String orderId) {
    var hash = 0;
    for (final codeUnit in orderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class PickupNotificationException implements Exception {
  const PickupNotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
