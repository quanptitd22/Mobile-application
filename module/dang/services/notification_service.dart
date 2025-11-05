import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/reminder_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  /// ✅ Khởi tạo notification service
  Future<void> initialize() async {
    // Khởi tạo timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Cấu hình Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Cấu hình iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Yêu cầu quyền thông báo
    await _requestPermissions();
  }

  /// 🔔 Xin quyền thông báo
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Xin quyền thông báo chính xác cho Android 12+
    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (plugin != null) {
      await plugin.requestNotificationsPermission();
      await plugin.requestExactAlarmsPermission();
    }
  }

  /// 📌 Xử lý khi người dùng nhấn vào thông báo
  void _onNotificationTapped(NotificationResponse response) {
    print('📌 Thông báo được nhấn: ${response.payload}');
    // TODO: Điều hướng đến màn hình chi tiết thuốc nếu cần
  }

  /// ⏰ Đặt thông báo cho một reminder
  Future<void> scheduleReminder(Reminder reminder) async {
    try {
      // Hủy tất cả thông báo cũ của reminder này
      await cancelReminderNotifications(reminder.id);

      // Tạo danh sách các thời điểm cần thông báo
      final schedules = reminder.generateSchedule();
      
      print('📅 Đang đặt ${schedules.length} thông báo cho ${reminder.title}');

      for (int i = 0; i < schedules.length; i++) {
        final scheduleTime = schedules[i];
        
        // Chỉ đặt thông báo cho thời gian trong tương lai
        if (scheduleTime.isAfter(DateTime.now())) {
          final notificationId = _generateNotificationId(reminder.id, i);
          
          await _scheduleNotification(
            id: notificationId,
            title: '💊 Nhắc nhở uống thuốc',
            body: '${reminder.title} - ${reminder.dosage} viên',
            scheduledTime: scheduleTime,
            payload: reminder.id,
          );
        }
      }

      print('✅ Đã đặt thông báo thành công cho ${reminder.title}');
    } catch (e) {
      print('❌ Lỗi khi đặt thông báo: $e');
    }
  }

  /// 🔕 Hủy tất cả thông báo của một reminder
  Future<void> cancelReminderNotifications(String reminderId) async {
    try {
      // Hủy tối đa 1000 thông báo có thể có của reminder này
      for (int i = 0; i < 1000; i++) {
        final notificationId = _generateNotificationId(reminderId, i);
        await _notifications.cancel(notificationId);
      }
      print('🔕 Đã hủy thông báo cho reminder: $reminderId');
    } catch (e) {
      print('❌ Lỗi khi hủy thông báo: $e');
    }
  }

  /// 🔕 Hủy tất cả thông báo
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🔕 Đã hủy tất cả thông báo');
  }

  /// ⏰ Đặt một thông báo cụ thể
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'medication_reminder_channel',
        'Medication Reminders',
        channelDescription: 'Thông báo nhắc nhở uống thuốc',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      print('⏰ Đã đặt thông báo #$id cho $scheduledTime');
    } catch (e) {
      print('❌ Lỗi khi đặt thông báo #$id: $e');
    }
  }

  /// 🔢 Tạo ID thông báo duy nhất
  int _generateNotificationId(String reminderId, int index) {
    // Tạo ID duy nhất từ reminderId và index
    return (reminderId.hashCode + index).abs() % 2147483647;
  }

  /// 📋 Lấy danh sách thông báo đang chờ
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 🧪 Hiển thị thông báo test ngay lập tức
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'medication_reminder_channel',
      'Medication Reminders',
      channelDescription: 'Thông báo nhắc nhở uống thuốc',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999,
      '🧪 Test Thông Báo',
      'Nếu bạn thấy thông báo này, tính năng hoạt động tốt!',
      notificationDetails,
    );
  }
}