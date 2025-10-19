import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_storage.dart';

/// 🔹 Lớp quản lý đọc/ghi dữ liệu Reminder lên Firestore theo từng user
/// Có đồng bộ 2 chiều với SharedPreferences
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

      // Đồng bộ local sau khi thêm
      await syncFromFirebaseToLocal();
    } catch (e) {
      print("❌ Lỗi khi thêm reminder: $e");
    }
  }

  /// 🟡 Cập nhật thuốc đã có
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).update(reminder.toJson());
      print("🟡 Đã cập nhật thuốc: ${reminder.title}");

      await syncFromFirebaseToLocal();
    } catch (e) {
      print("❌ Lỗi khi cập nhật reminder: $e");
    }
  }

  /// 🗑️ Xoá thuốc
  Future<void> deleteReminder(String id) async {
    try {
      await _reminderCollection.doc(id).delete();
      print("🗑️ Đã xoá thuốc có id: $id");

      await syncFromFirebaseToLocal();
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

  /// 🔄 Đồng bộ dữ liệu Firestore → SharedPreferences (local)
  Future<void> syncFromFirebaseToLocal() async {
    try {
      final reminders = await getAllReminders();
      await ReminderStorage.saveAllReminders(reminders);
      print("🔁 Đã đồng bộ dữ liệu từ Firebase xuống local");
    } catch (e) {
      print("❌ Lỗi khi đồng bộ dữ liệu: $e");
    }
  }

  /// 👀 Theo dõi thay đổi realtime từ Firestore
  /// Dữ liệu sẽ tự đồng bộ về local khi Firestore thay đổi
  void listenToRealtimeUpdates() {
    try {
      _reminderCollection.snapshots().listen((snapshot) async {
        final reminders = snapshot.docs
            .map((doc) => Reminder.fromJson(doc.data()))
            .toList();
        await ReminderStorage.saveAllReminders(reminders);
        print("🔔 Firestore cập nhật, đã đồng bộ realtime với local");
      });
    } catch (e) {
      print("❌ Lỗi khi theo dõi realtime: $e");
    }
  }

  /// 🚀 Gọi khi user đăng nhập thành công
  Future<void> initSyncForUser() async {
    await syncFromFirebaseToLocal(); // tải dữ liệu hiện có
    listenToRealtimeUpdates(); // bật theo dõi realtime
  }
  Future<void> updateReminderStatus(String id, String status) async {
    try {
      await _reminderCollection.doc(id).update({'status': status});
      print("✅ Đã cập nhật trạng thái của thuốc $id -> $status");
    } catch (e) {
      print("❌ Lỗi khi cập nhật trạng thái: $e");
    }
  }
  /// 🗑️ Xóa toàn bộ reminders có cùng tiêu đề (title)
  Future<void> deleteAllRemindersByTitle(String title) async {
    try {
      // 🔹 Lấy toàn bộ reminder có title trùng
      final snapshot = await _reminderCollection.where('title', isEqualTo: title).get();

      if (snapshot.docs.isEmpty) {
        print("⚠️ Không tìm thấy thuốc nào có title: $title");
        return;
      }

      // 🔹 Xóa từng reminder
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print("🗑️ Đã xoá thuốc có id: ${doc.id}");
      }

      // 🔹 Sau khi xóa xong, đồng bộ lại dữ liệu local
      final reminders = await getAllReminders();
      await ReminderStorage.saveAllReminders(reminders);

      print("✅ Đã xóa toàn bộ thuốc có title: $title");
    } catch (e) {
      print("❌ Lỗi khi xoá toàn bộ thuốc có title '$title': $e");
    }
  }
}
