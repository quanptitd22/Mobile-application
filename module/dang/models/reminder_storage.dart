import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_reminder_service.dart';

class Reminder {
  String id;
  String title;
  String description;
  int dosage;             // số lượng thuốc
  DateTime time;          // thời gian uống
  String frequency;       // ví dụ: "Hằng ngày", "X ngày 1 lần"
  int intervalDays;       // số ngày cách quãng
  DateTime? endDate;      // ngày kết thúc (có thể null)

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dosage,
    required this.time,
    this.frequency = "Hằng ngày",
    this.intervalDays = 1,
    this.endDate,
  });

  /// Chuyển sang JSON để lưu
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
    };
  }

  /// Parse từ JSON ra object
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dosage: json['dosage'],
      time: DateTime.parse(json['time']),
      frequency: json['frequency'] ?? "Hằng ngày",
      intervalDays: json['intervalDays'] ?? 1,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}

class ReminderStorage {
  static const String _key = 'reminders';

  /// Load danh sách reminders từ SharedPreferences
  static Future<List<Reminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_key);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Thêm reminder mới
  static Future<void> saveReminder(Reminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);

    // 🔹 Đồng bộ Firebase
    final firebaseService = FirebaseReminderService();
    await firebaseService.addReminder(reminder);
  }

  /// Cập nhật reminder
  static Future<void> updateReminder(Reminder updatedReminder) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await _saveReminders(reminders);

      // 🔹 Cập nhật Firebase
      final firebaseService = FirebaseReminderService();
      await firebaseService.updateReminder(updatedReminder);
    }
  }

  /// Xoá reminder theo id
  static Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);

    // 🔹 Xóa trên Firebase
    final firebaseService = FirebaseReminderService();
    await firebaseService.deleteReminder(id);
  }

  /// Xoá nhiều reminders
  static Future<void> deleteReminders(List<String> ids) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => ids.contains(r.id));
    await _saveReminders(reminders);

    // 🔹 Xóa nhiều trên Firebase
    final firebaseService = FirebaseReminderService();
    for (var id in ids) {
      await firebaseService.deleteReminder(id);
    }
  }

  /// Lưu danh sách reminders xuống SharedPreferences
  static Future<void> _saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
    json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
