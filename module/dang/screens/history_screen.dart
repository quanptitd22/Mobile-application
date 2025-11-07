import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_storage.dart';
import '../services/firebase_reminder_service.dart';
import 'reminder_screen.dart';

enum ReminderStatus { pending, completed, skipped }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseReminderService _firebaseService = FirebaseReminderService();

  List<Map<String, dynamic>> _allSchedules = [];
  List<Map<String, dynamic>> _filteredSchedules = [];
  final Map<String, ReminderStatus> _statuses = {};

  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = _getStartOfWeek(DateTime.now());

  static DateTime _getStartOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  final Gradient _primaryGradient = LinearGradient(
    colors: [Colors.blue.shade600, Colors.purple.shade600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _syncAndLoad();
  }

  /// 🔄 Đồng bộ Firebase ⇄ Local rồi tải danh sách lịch uống thuốc
  Future<void> _syncAndLoad() async {
    setState(() => _loading = true);
    try {
      // ⭐ Đồng bộ từ Firestore xuống local
      await _firebaseService.syncFromFirebaseToLocal();
      await _loadLocalSchedules();
      // ⭐ Tải trạng thái đã lưu từ Firebase
      await _loadStatusesFromFirebase();
    } catch (e) {
      debugPrint('⚠️ Lỗi đồng bộ dữ liệu: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 📂 Tải dữ liệu từ local storage
  Future<void> _loadLocalSchedules() async {
    final data = await ReminderStorage.getAllSchedules();
    setState(() {
      _allSchedules = data;
    });
    _filterByDate();
  }

  /// 📥 Tải trạng thái uống thuốc từ Firebase
  Future<void> _loadStatusesFromFirebase() async {
    try {
      final statuses = await _firebaseService.getAllReminderStatuses();
      setState(() {
        _statuses.clear();
        for (var entry in statuses.entries) {
          // Chuyển đổi string sang enum
          if (entry.value == 'completed') {
            _statuses[entry.key] = ReminderStatus.completed;
          } else if (entry.value == 'skipped') {
            _statuses[entry.key] = ReminderStatus.skipped;
          } else {
            _statuses[entry.key] = ReminderStatus.pending;
          }
        }
      });
      debugPrint('✅ Đã tải ${_statuses.length} trạng thái từ Firebase');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi tải trạng thái: $e');
    }
  }

  /// 📅 Lọc lịch uống thuốc theo ngày đang chọn
  void _filterByDate() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));

    setState(() {
      _filteredSchedules = _allSchedules.where((item) {
        final t = item['time'] as DateTime;
        return t.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.isBefore(end);
      }).toList();
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _filterByDate();
  }

  void _changeWeek(int direction) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * direction));
      _selectedDate = _weekStart;
    });
    _filterByDate();
  }

  List<DateTime> _getWeekDates() =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  /// 📅 Hiển thị cửa sổ chọn ngày để nhảy tuần
  Future<void> _selectDateRangeToJump() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _weekStart,
        end: _weekStart.add(const Duration(days: 6)),
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      final jumpDate = pickedRange.start;
      setState(() {
        _selectedDate = jumpDate;
        _weekStart = _getStartOfWeek(jumpDate);
      });
      _filterByDate();
    }
  }

  /// ✅ Ghi nhận trạng thái (đã uống / bỏ qua) và đồng bộ Firebase
  Future<void> _updateStatus(String id, ReminderStatus status) async {
    setState(() => _statuses[id] = status);

    try {
      await _firebaseService.updateReminderStatus(id, status.name);
      debugPrint('✅ Cập nhật trạng thái $id -> ${status.name}');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi cập nhật trạng thái: $e');
    }
  }

  Future<void> _handleSkip(String id, String title) async {
    await _updateStatus(id, ReminderStatus.skipped);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏭️ Đã bỏ qua: $title'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleFinish(String id, String title) async {
    await _updateStatus(id, ReminderStatus.completed);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💊 Đã uống: $title'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// 🛠️ Chuyển sang màn hình Chỉnh sửa
  Future<void> _editSchedule(Map<String, dynamic> item) async {
    final String? reminderId = item['reminderId'];

    if (reminderId == null) {
      _showErrorSnackBar('Lỗi: Không tìm thấy ID của lịch trình gốc.');
      return;
    }

    final reminder = await ReminderStorage.getReminderById(reminderId);

    if (reminder == null) {
      _showErrorSnackBar('Lỗi: Không thể tải lịch trình để chỉnh sửa.');
      return;
    }

    final updatedReminder = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderScreen(existingReminder: reminder),
      ),
    );

    if (updatedReminder != null) {
      await ReminderStorage.updateReminder(updatedReminder);
      _syncAndLoad();
    }
  }

  /// 🗑️ Xóa lịch thuốc (chỉ 1 lần hoặc toàn bộ)
  Future<void> _deleteSchedule(Map<String, dynamic> item) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                ),
                title: const Text('Xóa toàn bộ thuốc này'),
                onTap: () async {
                  await ReminderStorage.deleteAllByTitle(item['title']);
                  await _firebaseService.deleteAllRemindersByTitle(
                    item['title'],
                  );
                  Navigator.pop(context);
                  _syncAndLoad();
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

  /// ℹ️ Hiển thị SnackBar lỗi
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 🎨 Card hiển thị lịch thuốc từng khung giờ
  Widget _buildTimelineCard(Map<String, dynamic> item) {
    final time = item['time'] as DateTime;
    final id = '${item['title']}_${time.toIso8601String()}';
    final status = _statuses[id] ?? ReminderStatus.pending;

    Color getColor() {
      switch (status) {
        case ReminderStatus.completed:
          return Colors.green.shade500;
        case ReminderStatus.skipped:
          return Colors.orange.shade600;
        default:
          return Colors.blue.shade600;
      }
    }

    final color = getColor();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(width: 2, height: 180, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status == ReminderStatus.completed
                                  ? 'Đã uống'
                                  : status == ReminderStatus.skipped
                                  ? 'Đã bỏ qua'
                                  : 'Chờ uống',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteSchedule(item);
                              } else if (value == 'edit') {
                                _editSchedule(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Xóa thuốc'),
                                  ],
                                ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (item['description']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item['description'],
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Liều lượng: x${item['dosage']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  if (item['drawer'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ngăn: ${item['drawer']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (status == ReminderStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleSkip(id, item['title']),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.orange.shade600),
                              foregroundColor: Colors.orange.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Bỏ qua'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleFinish(id, item['title']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lịch sử uống thuốc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _syncAndLoad,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeWeek(-1),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _selectDateRangeToJump,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weekRange,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _changeWeek(1),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weekDates.length,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemBuilder: (context, i) {
                  final d = weekDates[i];
                  final selected = DateUtils.isSameDay(d, _selectedDate);
                  return GestureDetector(
                    onTap: () => _selectDate(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 65,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        gradient: selected ? _primaryGradient : null,
                        color: selected ? null : Colors.white,
                        border: selected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSchedules.isEmpty
                ? Center(
                    child: Text(
                      'Không có lịch trình nào',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  )
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