import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_storage.dart';
import 'reminder_screen.dart';

// Enum cho trạng thái
enum ReminderStatus {
  pending,   // Chưa xử lý
  completed, // Đã uống
  skipped    // Đã bỏ qua
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  // Map lưu trạng thái của từng reminder (key: reminder.id)
  final Map<String, ReminderStatus> _reminderStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadReminderStatuses();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _loading = true;
    });
    final data = await ReminderStorage.loadReminders();
    data.sort((a, b) => a.time.compareTo(b.time));
    setState(() {
      _reminders = data;
      _loading = false;
    });
    _filterRemindersByDate();
  }

  // Load trạng thái từ SharedPreferences
  Future<void> _loadReminderStatuses() async {
    for (var reminder in _reminders) {
      _reminderStatuses[reminder.id] = ReminderStatus.pending;
    }
  }

  // Lưu trạng thái vào SharedPreferences
  Future<void> _saveReminderStatus(String reminderId, ReminderStatus status) async {
    setState(() {
      _reminderStatuses[reminderId] = status;
    });
  }

  void _filterRemindersByDate() {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    setState(() {
      _filteredReminders = _reminders.where((r) {
        return r.time.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            r.time.isBefore(endOfDay);
      }).toList();
    });
  }

  Future<void> _addReminder() async {
    final newReminder = await Navigator.push<Reminder?>(
      context,
      MaterialPageRoute(builder: (_) => const ReminderScreen()),
    );
    if (newReminder != null) {
      await ReminderStorage.saveReminder(newReminder);
      await _loadReminders();
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _filterRemindersByDate();
  }

  List<DateTime> _getWeekDates() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Map<String, List<Reminder>> _groupRemindersByTime() {
    final Map<String, List<Reminder>> grouped = {};

    for (var reminder in _filteredReminders) {
      final timeKey = DateFormat('HH:mm').format(reminder.time);
      if (!grouped.containsKey(timeKey)) {
        grouped[timeKey] = [];
      }
      grouped[timeKey]!.add(reminder);
    }

    return grouped;
  }

  Future<void> _handleDelete(Reminder reminder) async {
    setState(() {
      _reminders.remove(reminder);
      _filteredReminders.remove(reminder);
      _reminderStatuses.remove(reminder.id);
    });

    await ReminderStorage.deleteReminder(reminder.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã xóa: ${reminder.title}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleSkip(Reminder reminder) async {
    await _saveReminderStatus(reminder.id, ReminderStatus.skipped);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã bỏ qua: ${reminder.title}'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleFinish(Reminder reminder) async {
    await _saveReminderStatus(reminder.id, ReminderStatus.completed);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Đã hoàn thành: ${reminder.title}'),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildReminderCard(Reminder reminder) {
    final status = _reminderStatuses[reminder.id] ?? ReminderStatus.pending;
    final isCompleted = status == ReminderStatus.completed;
    final isSkipped = status == ReminderStatus.skipped;

    return Opacity(
      opacity: (isCompleted || isSkipped) ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon bên trái - thay đổi theo trạng thái
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : isSkipped
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : isSkipped
                        ? Colors.orange
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isSkipped
                      ? Icons.cancel
                      : Icons.circle_outlined,
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : isSkipped
                      ? Colors.orange
                      : const Color(0xFFBDBDBD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Nội dung (title + description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (reminder.description != null && reminder.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          reminder.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),

                    // Hiển thị badge trạng thái
                    if (isCompleted || isSkipped)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'Đã uống' : 'Đã bỏ qua',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? const Color(0xFF4CAF50) : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // 2 nút Skip và Finish - chỉ hiện khi chưa xử lý
                    if (status == ReminderStatus.pending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Nút Skip
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleSkip(reminder),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Skip'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Nút Finish
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleFinish(reminder),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Finish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Nút xóa
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _handleDelete(reminder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final now = DateTime.now();
    final groupedReminders = _groupRemindersByTime();
    final sortedTimes = groupedReminders.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Chỉ phần tên màu xanh
            Container(
              color: const Color(0xFF1E88E5),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Minh Quan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            // Week Calendar - Nền trắng
            Container(
              color: Colors.white,
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: weekDates.length,
                itemBuilder: (context, index) {
                  final date = weekDates[index];
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;
                  final isToday = date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;

                  return GestureDetector(
                    onTap: () => _selectDate(date),
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[800],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // "Today" Label - Nền trắng
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Text(
                DateFormat('EEEE, d MMM', 'en_US').format(_selectedDate) ==
                    DateFormat('EEEE, d MMM', 'en_US').format(now)
                    ? 'Today, ${DateFormat('d MMM').format(_selectedDate)}'
                    : DateFormat('EEEE, d MMM').format(_selectedDate),
                style: const TextStyle(
                  color: Color(0xFF1E88E5),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Reminders List - Nền trắng
            Expanded(
              child: Container(
                color: Colors.white,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReminders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có lịch trình nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedTimes.length,
                  itemBuilder: (context, index) {
                    final time = sortedTimes[index];
                    final reminders = groupedReminders[time]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              time,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                          // Reminder Cards
                          ...reminders.map((reminder) => _buildReminderCard(reminder)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}