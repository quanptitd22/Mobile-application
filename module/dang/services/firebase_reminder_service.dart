import 'package:firebase_database/firebase_database.dart';
import '../models/reminder_storage.dart';

class FirebaseReminderService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref('reminders');

  /// Thêm reminder mới lên Firebase
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _db.child(reminder.id).set(reminder.toJson());
      print("Đã thêm thuốc lên Firebase: ${reminder.title}");
    } catch (e) {
      print("Lỗi khi thêm reminder lên Firebase: $e");
    }
  }

  /// Cập nhật reminder
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _db.child(reminder.id).update(reminder.toJson());
      print("Đã cập nhật thuốc trên Firebase: ${reminder.title}");
    } catch (e) {
      print("Lỗi khi cập nhật reminder: $e");
    }
  }

  /// Xoá reminder
  Future<void> deleteReminder(String id) async {
    try {
      await _db.child(id).remove();
      print("Đã xoá thuốc có id: $id");
    } catch (e) {
      print("Lỗi khi xoá reminder: $e");
    }
  }

  /// Lấy toàn bộ reminders từ Firebase
  Future<List<Reminder>> getAllReminders() async {
    try {
      final snapshot = await _db.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final reminders = data.values
            .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        print("Đã tải ${reminders.length} thuốc từ Firebase");
        return reminders;
      } else {
        print("Firebase trống, chưa có thuốc nào");
        return [];
      }
    } catch (e) {
      print("Lỗi khi tải dữ liệu từ Firebase: $e");
      return [];
    }
  }
}
