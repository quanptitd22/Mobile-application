import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime time;
  final String? description;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time.toIso8601String(),
      'description': description,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      time: DateTime.parse(json['time']),
      description: json['description'],
    );
  }
}

class ReminderStorage {
  static const String _key = 'reminders';

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

  static Future<void> saveReminder(Reminder reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);
  }

  static Future<void> updateReminder(Reminder updatedReminder) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await _saveReminders(reminders);
    }
  }

  static Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
  }

  static Future<void> deleteReminders(List<String> ids) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => ids.contains(r.id));
    await _saveReminders(reminders);
  }

  static Future<void> _saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}