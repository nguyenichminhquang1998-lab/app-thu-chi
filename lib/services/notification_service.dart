import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for the two notification use cases
/// this app needs: a recurring daily reminder to log expenses, and an
/// immediate alert when a category's spending crosses its budget.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _dailyReminderId = 1000;
  static const _androidChannelId = 'app_thu_chi_reminders';

  /// A browser cannot fire a scheduled reminder once the tab/PWA is closed,
  /// so every entry point below turns into a no-op on web and the reminder
  /// UI is hidden there (see SettingsScreen).
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// Requests notification permission and reports whether it was granted,
  /// so the caller can warn the user instead of silently scheduling
  /// reminders that will never actually show.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    if (kIsWeb) return;
    await init();
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: 'Đừng quên ghi chép chi tiêu hôm nay',
      body: 'Chỉ mất vài giây để cập nhật sổ thu chi của bạn.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'Nhắc nhở hằng ngày',
          channelDescription: 'Nhắc nhở ghi chép thu chi hằng ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: _dailyReminderId);
  }

  /// Fires an immediate notification so the user can confirm right away
  /// that notifications and sound actually work on their device, instead
  /// of waiting until the scheduled reminder time.
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      id: 999,
      title: 'Thông báo thử',
      body: 'Nếu bạn thấy và nghe được thông báo này, nhắc nhở hằng ngày sẽ hoạt động bình thường.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'Nhắc nhở hằng ngày',
          channelDescription: 'Nhắc nhở ghi chép thu chi hằng ngày',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBanner: true),
      ),
    );
  }

  Future<void> showBudgetAlert({
    required String categoryName,
    required double spent,
    required double budget,
  }) async {
    if (kIsWeb) return;
    await init();
    final overBudget = spent >= budget;
    await _plugin.show(
      id: categoryName.hashCode,
      title: overBudget ? 'Đã vượt ngân sách: $categoryName' : 'Sắp vượt ngân sách: $categoryName',
      body: overBudget
          ? 'Bạn đã chi vượt hạn mức đặt ra cho danh mục này trong kỳ này.'
          : 'Bạn đã dùng phần lớn ngân sách cho danh mục này trong kỳ này.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          'Cảnh báo ngân sách',
          channelDescription: 'Cảnh báo khi chi tiêu gần hoặc vượt ngân sách',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
