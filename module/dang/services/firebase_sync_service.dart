import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/reminder_storage.dart';

class FirebaseSyncService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _realtimeDB = FirebaseDatabase.instance.ref();

  /// 🔁 Đồng bộ toàn bộ reminders của user sang Realtime Database (cho IoT)
  Future<void> syncRemindersToRealtime() async {
    try {
      final user = _auth.currentUser;
      print("🔄 syncRemindersToRealtime() đang chạy...");
      if (user == null) {
        print("⚠️ Không có người dùng đăng nhập");
        return;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .get();

      // Chuyển tất cả Reminder sang dạng Map
      final reminders = snapshot.docs
          .map((doc) => Reminder.fromJson(doc.data()).toJson())
          .toList();

      // 🔹 Ghi lên Realtime Database tại /users/<uid>/reminders
      await _realtimeDB.child('users/${user.uid}/reminders').set(reminders);

      print("✅ Đồng bộ thành công ${reminders.length} reminders sang Realtime Database");
    } catch (e) {
      print("❌ Lỗi khi đồng bộ Realtime Database: $e");
    }
  }

  /// 🔁 Đọc lại dữ liệu từ Realtime Database (IoT → App)
  Future<List<Reminder>> getRemindersFromRealtime() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("⚠️ Chưa đăng nhập");

      final snapshot =
      await _realtimeDB.child('users/${user.uid}/reminders').get();

      if (!snapshot.exists) return [];

      final data = List<Map<String, dynamic>>.from(
        (snapshot.value as List)
            .where((e) => e != null)
            .map((e) => Map<String, dynamic>.from(e)),
      );

      final reminders = data.map((e) => Reminder.fromJson(e)).toList();

      print("📥 Lấy ${reminders.length} reminder từ Realtime Database");
      return reminders;
    } catch (e) {
      print("❌ Lỗi khi đọc Realtime Database: $e");
      return [];
    }
  }
}
