import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// 🔹 Model đại diện cho một thuốc cần nhắc
class Reminder {
  String id;
  final int? drawer;
  String title;
  String description;
  int dosage; // số lượng thuốc
  DateTime time; // thời gian uống đầu tiên
  String frequency; // ví dụ: "Hằng ngày", "X ngày 1 lần"
  int intervalDays; // số ngày cách quãng
  DateTime? endDate; // ngày kết thúc (có thể null)
  List<String> timesPerDay; // danh sách giờ uống trong ngày ["08:00", "20:00"]

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dosage,
    required this.time,
    this.frequency = "Hằng ngày",
    this.intervalDays = 1,
    this.endDate,
    this.timesPerDay = const ["08:00"], // mặc định 1 lần/ngày\
    this.drawer,
  });

  /// 🔹 Chuyển sang JSON để lưu
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dosage': dosage,
      'time': time.toIso8601String(),
      'frequency': frequency,
      'intervalDays': intervalDays,
      'endDate': endDate?.toIso8601String(),
      'timesPerDay': timesPerDay,
      'drawer': drawer,
    };
  }

  /// 🔹 Parse từ JSON ra object
  factory Reminder.fromJson(Map<String, dynamic> json) {
    // Hàm phụ để chuyển DateTime -> "HH:mm"
    String formatTime(DateTime time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    // Lấy danh sách giờ uống trong ngày
    List<String> parsedTimes = [];
    if (json['timesPerDay'] != null &&
        json['timesPerDay'] is List &&
        (json['timesPerDay'] as List).isNotEmpty) {
      parsedTimes = List<String>.from(json['timesPerDay']);
    } else if (json['time'] != null &&
        DateTime.tryParse(json['time'].toString()) != null) {
      // backward-compatible
      parsedTimes = [formatTime(DateTime.parse(json['time'].toString()))];
    } else {
      parsedTimes = ["08:00"];
    }
    return Reminder(
      drawer: json['drawer'] is int ? json['drawer'] : 1,
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Không tên',
      description: json['description']?.toString() ?? '',
      dosage: (json['dosage'] is int)
          ? json['dosage']
          : int.tryParse(json['dosage']?.toString() ?? '1') ?? 1,
      time: json['time'] is Timestamp
          ? (json['time'] as Timestamp).toDate()
          : (json['time'] != null && json['time'].toString().isNotEmpty
          ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
          : DateTime.now()),
      frequency: json['frequency']?.toString() ?? "Hằng ngày",
      intervalDays: (json['intervalDays'] is int)
          ? json['intervalDays']
          : int.tryParse(json['intervalDays']?.toString() ?? '1') ?? 1,
      endDate: json['endDate'] != null && json['endDate'].toString().isNotEmpty
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      timesPerDay: parsedTimes,
    );
  }


  /// 🔹 Sinh danh sách các thời điểm uống thuốc (theo logic thời gian)
  List<DateTime> generateSchedule() {
    List<DateTime> schedule = [];
    DateTime current = DateTime(time.year, time.month, time.day);
    DateTime end = endDate ?? current.add(const Duration(days: 30));

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      for (var t in timesPerDay) {
        final parts = t.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          schedule.add(DateTime(current.year, current.month, current.day, hour, minute));
        }
      }
      current = current.add(Duration(days: intervalDays));
    }

    return schedule;
  }
}

/// 🔹 Lớp xử lý lưu trữ + đồng bộ Firebase
class ReminderStorage {
  static String get _key {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? 'reminders_${user.uid}' : 'reminders_guest';
  }

  /// 🔸 Load danh sách reminders từ SharedPreferences
  static Future<List<Reminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      print("❌ Lỗi load reminders: $e");
      return [];
    }
  }

  /// 🔸 Thêm reminder mới
  static Future<void> saveReminder(Reminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);

    // 🔒 Chỉ đồng bộ nếu đã đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Không thể đồng bộ Firebase vì chưa đăng nhập");
      return;
    }

    // Đồng bộ Firebase
    final firebaseService = FirebaseReminderService();
    await firebaseService.addReminder(reminder);
  }

  /// 🔸 Cập nhật reminder
  static Future<void> updateReminder(Reminder updatedReminder) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await _saveReminders(reminders);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ Không thể đồng bộ Firebase vì chưa đăng nhập");
        return;
      }

      final firebaseService = FirebaseReminderService();
      await firebaseService.updateReminder(updatedReminder);
    }
  }

  /// 🔸 Xoá reminder theo id
  static Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Không thể đồng bộ Firebase vì chưa đăng nhập");
      return;
    }

    final firebaseService = FirebaseReminderService();
    await firebaseService.deleteReminder(id);
  }

  /// 🔸 Xoá nhiều reminders
  static Future<void> deleteReminders(List<String> ids) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => ids.contains(r.id));
    await _saveReminders(reminders);

    final firebaseService = FirebaseReminderService();
    for (var id in ids) {
      await firebaseService.deleteReminder(id);
    }
  }

  /// 🔸 Lưu toàn bộ reminders xuống SharedPreferences
  static Future<void> _saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  /// 🔸 Sinh toàn bộ lịch uống thuốc từ tất cả reminders
  static Future<List<Map<String, dynamic>>> getAllSchedules() async {
    final reminders = await loadReminders();
    List<Map<String, dynamic>> schedules = [];

    for (var reminder in reminders) {
      final schedule = reminder.generateSchedule();
      for (var time in schedule) {
        schedules.add({
          'id': "${reminder.id}_${time.toIso8601String()}",
          'title': reminder.title,
          'description': reminder.description,
          'dosage': reminder.dosage,
          'time': time,
          'drawer': reminder.drawer,

          'reminderId': reminder.id, // <-- Dòng này đã có, rất tốt!
        });
      }
    }

    // Sắp xếp theo thời gian
    schedules.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    return schedules;
  }

  // ================== BẮT ĐẦU CODE MỚI ==================
  /// 🔸 Lấy một Reminder cụ thể bằng ID (Dùng cho tính năng Chỉnh sửa)
  static Future<Reminder?> getReminderById(String id) async {
    final reminders = await loadReminders();
    try {
      // Dùng firstWhere để tìm
      return reminders.firstWhere((r) => r.id == id);
    } catch (e) {
      // firstWhere ném lỗi nếu không tìm thấy
      print("ℹ️ Không tìm thấy reminder với ID: $id");
      return null;
    }
  }
  // ================== KẾT THÚC CODE MỚI ==================


  // 🟡 THÊM MỚI: Xoá một lần thuốc cụ thể
  static Future<void> deleteScheduleOnce(Map<String, dynamic> schedule) async {
    final reminders = await loadReminders();

    // Tìm thuốc chứa lịch này
    final target = reminders.firstWhere(
          (r) => r.title == schedule['title'],
      orElse: () => Reminder(
        id: '',
        title: '',
        description: '',
        dosage: 0,
        time: DateTime.now(),
      ),
    );

    if (target.id.isEmpty) return; // Không tìm thấy thuốc

    // Xóa lịch cụ thể khỏi timesPerDay nếu có
    final time = schedule['time'] as DateTime;
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    target.timesPerDay.remove(timeStr);

    // Nếu thuốc không còn lần nào => xoá luôn
    if (target.timesPerDay.isEmpty) {
      reminders.removeWhere((r) => r.id == target.id);
      final firebaseService = FirebaseReminderService();
      await firebaseService.deleteReminder(target.id);
    }

    await _saveReminders(reminders);
  }

  // 🔴 THÊM MỚI: Xoá toàn bộ lịch theo tên thuốc
  static Future<void> deleteAllByTitle(String title) async {
    final reminders = await loadReminders();
    final toDelete = reminders.where((r) => r.title == title).toList();

    for (var r in toDelete) {
      final firebaseService = FirebaseReminderService();
      await firebaseService.deleteReminder(r.id);
    }

    reminders.removeWhere((r) => r.title == title);
    await _saveReminders(reminders);
  }

  static Future<void> saveAllReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  /// 🔄 Đồng bộ từ Firebase → SharedPreferences
  static Future<void> syncFromFirebaseToLocal() async {
    try {
      final firebaseService = FirebaseReminderService();
      final firebaseReminders = await firebaseService.getAllReminders();

      if (firebaseReminders.isNotEmpty) {
        await saveAllReminders(firebaseReminders);
        print("✅ Đã đồng bộ ${firebaseReminders.length} reminders từ Firebase xuống local.");
      } else {
        print("ℹ️ Không có dữ liệu trên Firebase.");
      }
    } catch (e) {
      print("❌ Lỗi khi đồng bộ từ Firebase: $e");
    }
  }
  // Hàm này đồng bộ local → RTDB theo user để thiết bị IoT đọc được
  static Future<void> syncLocalToRTDB() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Không thể đồng bộ RTDB vì chưa đăng nhập");
      return;
    }

    final reminders = await loadReminders();
    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/reminders');

    await ref.remove(); // Xóa cũ để tránh trùng
    for (var r in reminders) {
      await ref.child(r.id).set(r.toJson());
    }

    print("✅ Đã đồng bộ local → RTDB cho user ${user.uid}");
  }

}