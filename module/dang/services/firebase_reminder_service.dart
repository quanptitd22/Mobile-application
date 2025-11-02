import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_storage.dart';
import 'firebase_sync_service.dart';
import 'package:firebase_database/firebase_database.dart';

/// 🔹 Lớp quản lý đọc/ghi dữ liệu Reminder theo từng user riêng biệt
/// Mỗi user có dữ liệu riêng trong Firestore & Realtime Database
class FirebaseReminderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDB = FirebaseDatabase.instance;

  /// 🔐 Lấy collection reminders của user hiện tại
  CollectionReference<Map<String, dynamic>> get _reminderCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("⚠️ Người dùng chưa đăng nhập");
    return _firestore.collection('users').doc(user.uid).collection('reminders');
  }

  /// ✅ Thêm thuốc mới
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).set(reminder.toJson());

      await Future.delayed(const Duration(milliseconds: 300));

      // 🔐 Đồng bộ riêng theo uid
      await syncFromFirebaseToLocal();
      await syncFromFirebaseToRTDB();
      print("✅ Đã thêm thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi thêm reminder: $e");
    }
  }

  /// 🟡 Cập nhật thuốc đã có
  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _reminderCollection.doc(reminder.id).update(reminder.toJson());

      await Future.delayed(const Duration(milliseconds: 300));

      await syncFromFirebaseToLocal();
      await syncFromFirebaseToRTDB();
      print("🟡 Đã cập nhật thuốc: ${reminder.title}");
    } catch (e) {
      print("❌ Lỗi khi cập nhật reminder: $e");
    }
  }

  /// 🗑️ Xoá thuốc
  Future<void> deleteReminder(String id) async {
    try {
      await _reminderCollection.doc(id).delete();

      await Future.delayed(const Duration(milliseconds: 300));

      await syncFromFirebaseToLocal();
      await syncFromFirebaseToRTDB();
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

      print("📥 Đã tải ${reminders.length} thuốc từ Firestore (theo user)");
      return reminders;
    } catch (e) {
      print("❌ Lỗi khi tải reminders: $e");
      return [];
    }
  }

  /// 🔄 Đồng bộ Firestore → SharedPreferences (local)
  Future<void> syncFromFirebaseToLocal() async {
    try {
      final reminders = await getAllReminders();
      await ReminderStorage.saveAllReminders(reminders);
      print("🔁 Đã đồng bộ dữ liệu từ Firebase xuống local (user hiện tại)");
    } catch (e) {
      print("❌ Lỗi khi đồng bộ dữ liệu: $e");
    }
  }

  /// 👀 Theo dõi thay đổi realtime trong Firestore theo user
  void listenToRealtimeUpdates() {
    try {
      _reminderCollection.snapshots().listen((snapshot) async {
        final reminders = snapshot.docs
            .map((doc) => Reminder.fromJson(doc.data()))
            .toList();

        await ReminderStorage.saveAllReminders(reminders);
        await FirebaseSyncService().syncRemindersToRealtime();
        await syncFromFirebaseToRTDB();
        print("🔔 Firestore cập nhật (user hiện tại), đã đồng bộ realtime");
      });
    } catch (e) {
      print("❌ Lỗi khi theo dõi realtime: $e");
    }
  }

  /// 🚀 Khởi tạo khi user đăng nhập
  Future<void> initSyncForUser() async {
    await syncFromFirebaseToLocal();
    listenToRealtimeUpdates();
  }

  /// 🟢 Cập nhật trạng thái thuốc
  Future<void> updateReminderStatus(String id, String status) async {
    try {
      await _reminderCollection.doc(id).update({'status': status});
      await syncFromFirebaseToRTDB();
      print("✅ Cập nhật trạng thái thuốc $id -> $status (user hiện tại)");
    } catch (e) {
      print("❌ Lỗi khi cập nhật trạng thái: $e");
    }
  }

  /// 🗑️ Xóa toàn bộ reminders có cùng tiêu đề
  Future<void> deleteAllRemindersByTitle(String title) async {
    try {
      final snapshot =
      await _reminderCollection.where('title', isEqualTo: title).get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print("🗑️ Đã xoá thuốc có id: ${doc.id}");
      }

      final reminders = await getAllReminders();
      await ReminderStorage.saveAllReminders(reminders);
      await FirebaseSyncService().syncRemindersToRealtime();
      await syncFromFirebaseToRTDB();

      print("✅ Đã xoá toàn bộ thuốc có title: $title (user hiện tại)");
    } catch (e) {
      print("❌ Lỗi khi xoá thuốc có title '$title': $e");
    }
  }

  /// 🔁 Đồng bộ dữ liệu Firestore → Realtime Database riêng từng user
  Future<void> syncFromFirebaseToRTDB() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("⚠️ Người dùng chưa đăng nhập");

      final snapshot = await _reminderCollection.get();

      // 🔐 Ghi dữ liệu vào nhánh riêng của user
      final userRef = _realtimeDB.ref('users/${user.uid}/reminders');
      await userRef.remove(); // Xóa dữ liệu cũ để tránh trùng lặp

      for (var doc in snapshot.docs) {
        final data = doc.data();
        await userRef.child(doc.id).set({
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'dosage': data['dosage'] ?? 1,
          'time': data['time'] ?? '',
          'frequency': data['frequency'] ?? 'Hằng ngày',
          'intervalDays': data['intervalDays'] ?? 1,
          'endDate': data['endDate'] ?? '',
          'timesPerDay': List<String>.from(data['timesPerDay'] ?? []),
        });
      }

      print('✅ Đồng bộ Firestore → RTDB thành công cho user ${user.uid}');
    } catch (e) {
      print('❌ Lỗi khi đồng bộ Firestore sang RTDB: $e');
    }
  }
}
