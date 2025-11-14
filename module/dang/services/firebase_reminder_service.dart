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

  /// 🔐 Lấy collection statuses của user hiện tại
  CollectionReference<Map<String, dynamic>> get _statusCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("⚠️ Người dùng chưa đăng nhập");
    return _firestore.collection('users').doc(user.uid).collection('statuses');
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
      final reminders = snapshot.docs.map((doc) {
        final data = doc.data();

        // ép timesPerDay luôn đúng kiểu List<String>
        List<String> parseTimes(dynamic value) {
          if (value == null) return [];
          if (value is List) return value.map((e) => e.toString()).toList();
          if (value is String && value.contains(',')) {
            return value.split(',').map((e) => e.trim()).toList();
          }
          if (value is String && value.isNotEmpty) {
            return [value.trim()];
          }
          return [];
        }

        // ép kiểu đúng và truyền thủ công để tránh parse sai
        return Reminder(
          id: data['id']?.toString() ?? doc.id,
          title: data['title']?.toString() ?? 'Không tên',
          description: data['description']?.toString() ?? '',
          dosage: (data['dosage'] is int)
              ? data['dosage']
              : int.tryParse(data['dosage']?.toString() ?? '1') ?? 1,
          time: (data['time'] is Timestamp)
              ? data['time'].toDate()
              : DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now(),
          frequency: data['frequency']?.toString() ?? "Hằng ngày",
          intervalDays: (data['intervalDays'] is int)
              ? data['intervalDays']
              : int.tryParse(data['intervalDays']?.toString() ?? '1') ?? 1,
          endDate: data['endDate'] != null && data['endDate'].toString().isNotEmpty
              ? DateTime.tryParse(data['endDate'].toString())
              : null,
          timesPerDay: parseTimes(data['timesPerDay']),
          drawer: data['drawer'] is int ? data['drawer'] : 1,
        );
      }).toList();

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
      await _statusCollection.doc(id).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Cập nhật trạng thái thuốc $id -> $status (user hiện tại)");
    } catch (e) {
      print("❌ Lỗi khi cập nhật trạng thái: $e");
    }
  }

  /// 📥 Lấy tất cả trạng thái thuốc đã lưu
  Future<Map<String, String>> getAllReminderStatuses() async {
    try {
      final snapshot = await _statusCollection.get();
      final Map<String, String> statuses = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        statuses[doc.id] = data['status']?.toString() ?? 'pending';
      }
      
      print("📥 Đã tải ${statuses.length} trạng thái từ Firebase");
      return statuses;
    } catch (e) {
      print("❌ Lỗi khi tải trạng thái: $e");
      return {};
    }
  }

  /// 📊 Thống kê số lượng theo trạng thái
   //Future<Map<String, int>> getStatusStatistics() async {
  //   try {
  //     final snapshot = await _statusCollection.get();
      
      // int completed = 0;
      // int skipped = 0;
      // int pending = 0;
      
      // for (var doc in snapshot.docs) {
      //   final data = doc.data();
      //   final status = data['status']?.toString() ?? 'pending';
        
      //   if (status == 'completed') {
      //     completed++;
      //   } else if (status == 'skipped') {
      //     skipped++;
      //   } else {
      //     pending++;
      //   }
      // }
      
      // Tính tổng số lịch trình (từ reminders)
      // final allSchedules = await ReminderStorage.getAllSchedules();
      // final totalSchedules = allSchedules.length;
      
      // Số lịch chờ = tổng - đã uống - đã bỏ qua
      // final actualPending = totalSchedules - completed - skipped;
      
      // print("📊 Thống kê: Đã uống: $completed, Đã bỏ qua: $skipped, Sắp tới: $actualPending");
      
  //     return {
  //       'completed': completed,
  //       'skipped': skipped,
  //       'pending': actualPending > 0 ? actualPending : pending,
  //       'total': totalSchedules,
  //     };
  //   } catch (e) {
  //     print("❌ Lỗi khi thống kê: $e");
  //     return {
  //       'completed': 0,
  //       'skipped': 0,
  //       'pending': 0,
  //       'total': 0,
  //     };
  //   }
  // }

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
          'timesPerDay': data['timesPerDay'] ?? ['08:00'],
          'drawer': data['drawer'] ?? 1,
        });
      }
      print('✅ Đồng bộ Firestore → RTDB thành công cho user ${user.uid}');
    } catch (e) {
      print('❌ Lỗi khi đồng bộ Firestore sang RTDB: $e');
    }
  }
}