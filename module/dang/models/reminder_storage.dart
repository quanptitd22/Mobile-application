// module/models/reminder_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model class for a Reminder
class Reminder {
  final String id;
  final String title;
  final DateTime time;

  Reminder({
    required this.id,
    required this.title,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'time': time.toIso8601String(),
  };

  static Reminder fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    time: DateTime.parse(json['time']),
  );
}

/// Storage class for handling reminders with SharedPreferences
class ReminderStorage {
  static const _key = 'reminders';

  /// Load all reminders from SharedPreferences
  static Future<List<Reminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList(_key) ?? [];
      return data.map((e) => Reminder.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      print('Error loading reminders: $e');
      return [];
    }
  }

  /// Save a new reminder
  static Future<void> saveReminder(Reminder reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await loadReminders();
      reminders.add(reminder);

      final data = reminders.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_key, data);
    } catch (e) {
      print('Error saving reminder: $e');
    }
  }

  /// Update a reminder by id
  static Future<void> updateReminder(Reminder updated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await loadReminders();

      final index = reminders.indexWhere((r) => r.id == updated.id);
      if (index != -1) {
        reminders[index] = updated;
        final data = reminders.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList(_key, data);
      }
    } catch (e) {
      print('Error updating reminder: $e');
    }
  }

  /// Delete a reminder by id
  static Future<void> deleteReminder(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await loadReminders();

      reminders.removeWhere((r) => r.id == id);

      final data = reminders.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_key, data);
    } catch (e) {
      print('Error deleting reminder: $e');
    }
  }

  /// Clear all reminders
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing reminders: $e');
    }
  }
}
