import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_reminder_service.dart';

/// 🔹 Model đại diện cho một thuốc cần nhắc
class Reminder {
  String id;
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
    this.timesPerDay = const ["08:00"], // mặc định 1 lần/ngày
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
    };
  }

  /// 🔹 Parse từ JSON ra object
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dosage: json['dosage'] ?? 1,
      time: DateTime.parse(json['time']),
      frequency: json['frequency'] ?? "Hằng ngày",
      intervalDays: json['intervalDays'] ?? 1,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      timesPerDay: (json['timesPerDay'] != null)
          ? List<String>.from(json['timesPerDay'])
          : ["08:00"],
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
  static const String _key = 'reminders';

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

      final firebaseService = FirebaseReminderService();
      await firebaseService.updateReminder(updatedReminder);
    }
  }

  /// 🔸 Xoá reminder theo id
  static Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);

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
        });
      }
    }

    // Sắp xếp theo thời gian
    schedules.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    return schedules;
  }

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
}
