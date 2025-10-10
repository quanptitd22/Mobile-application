import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_storage.dart';

enum ReminderStatus { pending, completed, skipped }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = _getStartOfWeek(DateTime.now());

  final Map<String, ReminderStatus> _statuses = {};

  static DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1)); // Monday
  }

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _loading = true);
    final schedules = await ReminderStorage.getAllSchedules();
    schedules.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    setState(() {
      _schedules = schedules;
      _loading = false;
    });
    _filterByDate();
  }

  void _filterByDate() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    setState(() {
      _filteredSchedules = _schedules.where((item) {
        final t = item['time'] as DateTime;
        return t.isAfter(start.subtract(const Duration(seconds: 1))) && t.isBefore(end);
      }).toList();
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _filterByDate();
  }

  void _changeWeek(int direction) {
    // direction = -1: previous week, +1: next week
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      _selectedDate = _weekStart; // chọn lại ngày đầu tuần
    });
    _filterByDate();
  }

  List<DateTime> _getWeekDates() {
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  Future<void> _updateStatus(String id, ReminderStatus status) async {
    setState(() => _statuses[id] = status);
  }

  Future<void> _handleSkip(String id, String title) async {
    await _updateStatus(id, ReminderStatus.skipped);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã bỏ qua: $title'), backgroundColor: Colors.orange),
    );
  }

  Future<void> _handleFinish(String id, String title) async {
    await _updateStatus(id, ReminderStatus.completed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã uống: $title'), backgroundColor: Colors.green),
    );
  }

  Future<void> _deleteSchedule(Map<String, dynamic> item) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa chỉ lần này'),
                onTap: () async {
                  await ReminderStorage.deleteScheduleOnce(item);
                  Navigator.pop(context);
                  _loadSchedules();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Xóa toàn bộ thuốc này'),
                onTap: () async {
                  await ReminderStorage.deleteAllByTitle(item['title']);
                  Navigator.pop(context);
                  _loadSchedules();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Hủy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> item) {
    final time = item['time'] as DateTime;
    final id = '${item['title']}_${time.toIso8601String()}';
    final status = _statuses[id] ?? ReminderStatus.pending;
    final isCompleted = status == ReminderStatus.completed;
    final isSkipped = status == ReminderStatus.skipped;

    Color getColor() {
      if (isCompleted) return Colors.green;
      if (isSkipped) return Colors.orange;
      return Colors.blue;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline cột trái
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: getColor(), shape: BoxShape.circle),
            ),
            Container(width: 2, height: 80, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),

        // Card thông tin thuốc
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng đầu: thời gian + trạng thái + menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCompleted
                                  ? 'Đã uống'
                                  : isSkipped
                                  ? 'Đã bỏ qua'
                                  : 'Chờ uống',
                              style: TextStyle(
                                color: getColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              if (value == 'delete') _deleteSchedule(item);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Xóa thuốc'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] ?? 'Không rõ tên',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (item['description'] != null && item['description'] != '')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item['description'],
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Liều lượng: x${item['dosage']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // Nút thao tác
                  if (status == ReminderStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleSkip(id, item['title']),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                            ),
                            child: const Text('Bỏ qua'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleFinish(id, item['title']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Đã uống'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final weekRange =
        '${DateFormat('d MMM').format(weekDates.first)} - ${DateFormat('d MMM').format(weekDates.last)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lịch sử uống thuốc'),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tuần (có nút < >)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeWeek(-1),
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                ),
                Text(
                  weekRange,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeWeek(1),
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ],
            ),
          ),

          // Danh sách ngày trong tuần
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDates.length,
              itemBuilder: (context, i) {
                final d = weekDates[i];
                final selected = DateUtils.isSameDay(d, _selectedDate);
                return GestureDetector(
                  onTap: () => _selectDate(d),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2196F3) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(d),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Nội dung lịch
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSchedules.isEmpty
                ? const Center(child: Text('Không có lịch trình nào'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSchedules.length,
              itemBuilder: (context, i) =>
                  _buildTimelineCard(_filteredSchedules[i]),
            ),
          ),
        ],
      ),
    );
  }
}
