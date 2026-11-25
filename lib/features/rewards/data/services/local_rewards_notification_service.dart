import 'package:ecotrash/features/rewards/domain/entities/reward.dart';
import 'package:ecotrash/features/rewards/domain/services/rewards_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class LocalRewardsNotificationService implements RewardsNotificationService {
  LocalRewardsNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<bool> requestPermission() async {
    await _initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  @override
  Future<void> redemptionSucceeded(RewardVoucher voucher) async {
    await _initialize();
    await _plugin.show(
      id: _notificationId(voucher.id),
      title: 'Penukaran berhasil',
      body: '${voucher.title} berhasil ditukar di EcoTrash.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rewards_updates',
          'Pembaruan Rewards',
          channelDescription: 'Informasi penukaran dan masa berlaku reward.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  Future<void> scheduleExpiryReminder(RewardVoucher voucher) async {
    await _initialize();
    final reminderAt = voucher.expiresAt.subtract(const Duration(days: 3));
    if (!reminderAt.isAfter(DateTime.now())) {
      return;
    }
    await _plugin.zonedSchedule(
      id: _notificationId('${voucher.id}-expiry'),
      title: 'Voucher EcoTrash segera kedaluwarsa',
      body: '${voucher.title} akan kedaluwarsa dalam 3 hari.',
      scheduledDate: _toLocalTime(reminderAt),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rewards_updates',
          'Pembaruan Rewards',
          channelDescription: 'Informasi penukaran dan masa berlaku reward.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _initialize() async {
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
      throw StateError('Notifikasi Rewards tidak dapat diinisialisasi.');
    }
    _initialized = true;
  }

  timezone.TZDateTime _toLocalTime(DateTime value) =>
      timezone.TZDateTime.from(value, timezone.local);

  int _notificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
