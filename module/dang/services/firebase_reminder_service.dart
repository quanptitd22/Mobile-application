import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_storage.dart';

/// 🔹 Lớp quản lý đọc/ghi dữ liệu Reminder lên Firestore theo từng user
class FirebaseReminderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔸 Collection reminders của user hiện tại
  CollectionReference<Map<String, dynamic>> get _reminderCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("⚠️ Người dùng chưa đăng nhập");
    return _firestore.collection('users').doc(user.uid).collection('reminders');
  }

  /// ✅ Thêm thuốc mới lên Firestore
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).set(reminder.toJson());
      print("✅ Đã thêm thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi thêm reminder: $e");
    }
  }

  /// 🟡 Cập nhật thuốc đã có
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).update(reminder.toJson());
      print("🟡 Đã cập nhật thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi cập nhật reminder: $e");
    }
  }

  /// 🗑️ Xoá thuốc
  Future<void> deleteReminder(String id) async {
    try {
      await _reminderCollection.doc(id).delete();
      print("🗑️ Đã xoá thuốc có id: $id");
    } catch (e) {
      print("❌ Lỗi khi xoá reminder: $e");
    }
  }

  /// 📥 Lấy toàn bộ reminders của user hiện tại
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

  /// 🔄 Đồng bộ dữ liệu Firestore ↔ SharedPreferences
  Future<void> syncFromFirebaseToLocal() async {
    try {
      final reminders = await getAllReminders();
      await ReminderStorage.saveAllReminders(reminders);
      print("🔁 Đã đồng bộ dữ liệu từ Firebase xuống local");
    } catch (e) {
      print("❌ Lỗi khi đồng bộ dữ liệu: $e");
    }
  }
}
