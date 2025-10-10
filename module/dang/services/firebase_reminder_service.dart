import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_storage.dart';

class FirebaseReminderService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Trả về collection tương ứng với user hiện tại
  CollectionReference<Map<String, dynamic>> get _reminderCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Người dùng chưa đăng nhập");
    }
    return _firestore.collection('users').doc(user.uid).collection('reminders');
  }

  /// Thêm reminder mới
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).set(reminder.toJson());
      print("✅ Đã thêm thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi thêm reminder: $e");
    }
  }

  /// Cập nhật reminder
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).update(reminder.toJson());
      print("✅ Đã cập nhật thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi cập nhật reminder: $e");
    }
  }

  /// 🔴 Xoá reminder
  Future<void> deleteReminder(String id) async {
    try {
      await _reminderCollection.doc(id).delete();
      print("🗑️ Đã xoá thuốc có id: $id");
    } catch (e) {
      print("❌ Lỗi khi xoá reminder: $e");
    }
  }

  /// 📦 Lấy toàn bộ reminders của user hiện tại
  Future<List<Reminder>> getAllReminders() async {
    try {
      final snapshot = await _reminderCollection.get();
      final reminders = snapshot.docs
          .map((doc) => Reminder.fromJson(doc.data()))
          .toList();

      print("📥 Đã tải ${reminders.length} thuốc từ Firestore");
      return reminders;
    } catch (e) {
      print("❌ Lỗi khi tải reminders: $e");
      return [];
    }
  }
}
