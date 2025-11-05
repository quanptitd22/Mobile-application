import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_reminder_service.dart';
import '../services/notification_service.dart';
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
    this.timesPerDay = const ["08:00"],
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
    List<String> parseTimes(dynamic value, DateTime time) {
      if (value == null) {
        return [
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
        ];
      } else if (value is List) {
        return value.map((e) => e.toString()).toList();
      } else if (value is String) {
        return value.split(',').map((e) => e.trim()).toList();
      } else {
        return ["08:00"];
      }
    }

    final parsedTime = json['time'] is Timestamp
        ? (json['time'] as Timestamp).toDate()
        : (json['time'] != null && json['time'].toString().isNotEmpty
              ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
              : DateTime.now());

    return Reminder(
      drawer: json['drawer'] is int ? json['drawer'] : 1,
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Không tên',
      description: json['description']?.toString() ?? '',
      dosage: (json['dosage'] is int)
          ? json['dosage']
          : int.tryParse(json['dosage']?.toString() ?? '1') ?? 1,
      time: parsedTime,
      frequency: json['frequency']?.toString() ?? "Hằng ngày",
      intervalDays: (json['intervalDays'] is int)
          ? json['intervalDays']
          : int.tryParse(json['intervalDays']?.toString() ?? '1') ?? 1,
      endDate: json['endDate'] != null && json['endDate'].toString().isNotEmpty
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      timesPerDay: parseTimes(json['timesPerDay'], parsedTime),
    );
  }

  /// 🔹 Chuyển Map (Firebase snapshot) thành Reminder object
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder.fromJson(map);
  }

  /// 🔹 Sinh danh sách các thời điểm uống thuốc (theo logic thời gian)
  List<DateTime> generateSchedule() {
    List<DateTime> schedule = [];
    DateTime current = DateTime(time.year, time.month, time.day);
    DateTime end = endDate ?? current.add(const Duration(days: 30));

    for (
      DateTime d = current;
      !d.isAfter(end);
      d = d.add(Duration(days: intervalDays))
    ) {
      for (var t in timesPerDay) {
        if (t.isEmpty) continue;
        final parts = t.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          schedule.add(DateTime(d.year, d.month, d.day, hour, minute));
        }
      }
    }

    final unique = schedule.toSet().toList()..sort((a, b) => a.compareTo(b));
    return unique;
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Không thể đồng bộ Firebase vì chưa đăng nhập");
      return;
    }

    final firebaseService = FirebaseReminderService();
    await firebaseService.addReminder(reminder);

    // ✅ Đặt thông báo cho reminder mới
    await NotificationService().scheduleReminder(reminder);
    print("🔔 Đã đặt thông báo cho: ${reminder.title}");
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

      // ✅ Cập nhật thông báo
      await NotificationService().scheduleReminder(updatedReminder);
      print("🔔 Đã cập nhật thông báo cho: ${updatedReminder.title}");
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

    // ✅ Hủy thông báo
    await NotificationService().cancelReminderNotifications(id);
    print("🔕 Đã hủy thông báo cho reminder: $id");
  }

  static Future<void> rescheduleAllNotifications() async {
    final reminders = await loadReminders();

    // Hủy tất cả thông báo cũ
    await NotificationService().cancelAllNotifications();

    // Đặt lại thông báo cho tất cả reminders
    for (var reminder in reminders) {
      await NotificationService().scheduleReminder(reminder);
    }

    print("🔄 Đã đặt lại ${reminders.length} thông báo");
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
      // Sử dụng ngày bắt đầu từ reminder
      final startDate = reminder.time;
      final schedule = reminder.generateSchedule();

      for (var time in schedule) {
        // Tạo DateTime với ngày từ lịch và giờ từ time
        final scheduleDateTime = DateTime(
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        );

        schedules.add({
          'id': "${reminder.id}_${scheduleDateTime.toIso8601String()}",
          'title': reminder.title,
          'description': reminder.description,
          'dosage': reminder.dosage,
          'time': scheduleDateTime,
          'drawer': reminder.drawer,
          'reminderId': reminder.id,
          'frequency': reminder.frequency,
          'startDate': startDate,
        });
      }
    }

    schedules.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );
    return schedules;
  }

  static Future<void> saveAllReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  static Future<void> syncFromFirebaseToLocal() async {
    try {
      final firebaseService = FirebaseReminderService();
      final firebaseReminders = await firebaseService.getAllReminders();

      if (firebaseReminders.isNotEmpty) {
        await saveAllReminders(firebaseReminders);
        print(
          "✅ Đã đồng bộ ${firebaseReminders.length} reminders từ Firebase xuống local.",
        );
      } else {
        print("ℹ️ Không có dữ liệu trên Firebase.");
      }
    } catch (e) {
      print("❌ Lỗi khi đồng bộ từ Firebase: $e");
    }
  }

  static Future<void> syncLocalToRTDB() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ Không thể đồng bộ RTDB vì chưa đăng nhập");
      return;
    }

    final reminders = await loadReminders();
    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/reminders');

    await ref.remove();
    for (var r in reminders) {
      await ref.child(r.id).set(r.toJson());
    }

    print("✅ Đã đồng bộ local → RTDB cho user ${user.uid}");
  }

  /// 🔸 Lấy nhắc nhở theo ID (trả về Reminder)
  static Future<Reminder?> getReminderById(String id) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('reminders')
          .child(id)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return Reminder.fromMap(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting reminder by ID: $e');
      return null;
    }
  }

  /// 🔸 Xóa tất cả nhắc nhở theo tiêu đề
  static Future<void> deleteAllByTitle(String title) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('reminders').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map;
        data.forEach((key, value) async {
          final item = Map<String, dynamic>.from(value);
          if (item['title'] == title) {
            await FirebaseDatabase.instance
                .ref('reminders')
                .child(key)
                .remove();
          }
        });
      }
    } catch (e) {
      print('Error deleting reminders by title: $e');
    }
  }

  /// Generate a stable notification id for a reminder occurrence
  static int _notificationIdFor(String reminderId, DateTime time) {
    // Ensure a positive 32-bit int
    return (reminderId.hashCode ^ time.millisecondsSinceEpoch) & 0x7fffffff;
  }

  /// Public wrapper to get a notification id for external callers
  static int notificationIdFor(String reminderId, DateTime time) =>
      _notificationIdFor(reminderId, time);
}
