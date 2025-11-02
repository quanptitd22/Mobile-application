import '../models/reminder_storage.dart';
// import 'notification_service.dart';


class StorageService {
  /// Load tất cả reminders
  static Future<List<Reminder>> loadReminders() async {
    return await ReminderStorage.loadReminders();
  }

  /// Thêm reminder + tạo notification
  static Future<void> addReminder(Reminder reminder, DateTime time) async {
    await ReminderStorage.saveReminder(reminder);

    // Tạo notification gắn với reminder.id
    // await NotificationService().scheduleNotification(
    //   id: reminder.id.hashCode,
    //   title: 'Medication Reminder',
    //   body: reminder.title,
    //   scheduledTime: time,
    // );
  }

  /// Xoá reminder + huỷ notification
  static Future<void> deleteReminder(Reminder reminder) async {
    await ReminderStorage.deleteReminder(reminder.id);
    // await NotificationService().cancelNotification(reminder.id.hashCode);
  }

  /// Update reminder + update notification
  static Future<void> updateReminder(Reminder updated, DateTime time) async {
    await ReminderStorage.updateReminder(updated);
    // await NotificationService().cancelNotification(updated.id.hashCode);
    // await NotificationService().scheduleNotification(
    //   id: updated.id.hashCode,
    //   title: 'Medication Reminder',
    //   body: updated.title,
    //   scheduledTime: time,
    // );
  }
}
