import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_storage.dart';
import 'reminder_screen.dart';

// Giả định lớp Reminder đã được định nghĩa trong reminder_storage.dart
// class Reminder {
//   final String id;
//   final String title;
//   final String? description;
//   final DateTime time;
//   Reminder({required this.id, required this.title, this.description, required this.time});
// }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  bool _loading = true;

  bool _isDeleteMode = false;
  bool _isEditMode = false;
  final Set<String> _selectedReminders = {};
  bool _selectAll = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- Biến mới cho lọc theo ngày ---
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDateRange = 'Hôm nay'; // 'Hôm nay', 'Tuần này', 'Tháng này', 'Tất cả', 'Tùy chỉnh'
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    _loadReminders();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterReminders();
    });
  }

  // --- Cập nhật logic lọc để bao gồm lọc theo ngày ---
  void _filterReminders() {
    List<Reminder> result = List.from(_reminders);

    // 1. Lọc theo tìm kiếm (Search)
    if (_searchQuery.isNotEmpty) {
      result = result.where((reminder) {
        return reminder.title.toLowerCase().contains(_searchQuery) ||
            (reminder.description.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // 2. Lọc theo khoảng thời gian (Date Range)
    final now = DateTime.now();
    DateTime? effectiveStartDate;
    DateTime? effectiveEndDate;

    switch (_selectedDateRange) {
      case 'Hôm nay':
        effectiveStartDate = DateTime(now.year, now.month, now.day);
        effectiveEndDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        break;
      case 'Tuần này':
      // Tuần bắt đầu từ Thứ Hai (weekday 1)
        final startOfWeek = now.subtract(Duration(days: now.weekday == 7 ? 6 : now.weekday - 1));
        effectiveStartDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        effectiveEndDate = effectiveStartDate.add(const Duration(days: 7));
        break;
      case 'Tháng này':
        effectiveStartDate = DateTime(now.year, now.month, 1);
        effectiveEndDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Tùy chỉnh':
        effectiveStartDate = _startDate != null ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day) : null;
        effectiveEndDate = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day).add(const Duration(days: 1)) : null;
        break;
      case 'Tất cả':
      default:
      // Không lọc ngày
        break;
    }

    // Áp dụng bộ lọc ngày
    if (effectiveStartDate != null) {
      result = result.where((r) => r.time.isAtSameMomentAs(effectiveStartDate!) || r.time.isAfter(effectiveStartDate)).toList();
    }
    if (effectiveEndDate != null) {
      result = result.where((r) => r.time.isBefore(effectiveEndDate!)).toList();
    }

    // Cập nhật danh sách hiển thị
    setState(() {
      _filteredReminders = result;
    });
  }
  // ----------------------------------------------------

  Future<void> _loadReminders() async {
    setState(() {
      _loading = true;
    });
    final data = await ReminderStorage.loadReminders();
    // Sort by time (newest first)
    data.sort((a, b) => b.time.compareTo(a.time));
    setState(() {
      _reminders = data;
      _loading = false;
    });
    _filterReminders(); // Thay thế việc gán _filteredReminders = List.from(data) bằng hàm lọc
    _fabAnimationController.forward();
  }

  Future<void> _addReminder() async {
    final newReminder = await Navigator.push<Reminder?>(
      context,
      MaterialPageRoute(builder: (_) => const ReminderScreen()),
    );
    if (newReminder != null) {
      await ReminderStorage.saveReminder(newReminder);
      await _loadReminders();
      _showSuccessSnackBar('Đã thêm lịch trình mới');
    }
  }

  Future<void> _editReminder(Reminder reminder) async {
    final updated = await Navigator.push<Reminder?>(
      context,
      MaterialPageRoute(builder: (_) => ReminderScreen(existingReminder: reminder)),
    );
    if (updated != null) {
      await ReminderStorage.updateReminder(updated);
      await _loadReminders();
      _showSuccessSnackBar('Cập nhật thành công');
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedReminders.isEmpty) return;

    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    final deletedCount = _selectedReminders.length;
    await ReminderStorage.deleteReminders(_selectedReminders.toList());

    setState(() {
      _isDeleteMode = false;
      _selectAll = false;
      _selectedReminders.clear();
    });
    await _loadReminders();
    _showSuccessSnackBar('Đã xóa $deletedCount lịch trình');
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa ${_selectedReminders.length} lịch trình đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (_isDeleteMode) {
        _isEditMode = false;
      } else {
        _selectedReminders.clear();
        _selectAll = false;
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _isDeleteMode = false;
        _selectedReminders.clear();
        _selectAll = false;
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _selectedReminders.clear();
      if (_selectAll) {
        _selectedReminders.addAll(_filteredReminders.map((r) => r.id));
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // --- Các phương thức UI mới cho bộ chọn ngày ---
  Widget _buildDateRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildDateRangeChip('Hôm nay'),
          _buildDateRangeChip('Tuần này'),
          _buildDateRangeChip('Tháng này'),
          _buildDateRangeChip('Tất cả'),
          _buildCustomDateRangeChip(),
        ],
      ),
    );
  }

  Widget _buildDateRangeChip(String label) {
    final isSelected = _selectedDateRange == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedDateRange = label;
              _startDate = null;
              _endDate = null;
            });
            _filterReminders();
          }
        },
        selectedColor: const Color(0xFF2196F3).withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2196F3) : (Colors.grey[300] ?? Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateRangeChip() {
    final isSelected = _selectedDateRange == 'Tùy chỉnh';
    final label = (_startDate != null && _endDate != null)
        ? '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}'
        : 'Tùy chỉnh';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: isSelected ? const Icon(Icons.calendar_month, size: 18, color: Color(0xFF2196F3)) : null,
        label: Text(label),
        onPressed: _showDateRangePicker,
        backgroundColor: isSelected ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF2196F3) : (Colors.grey[300] ?? Colors.grey),
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final initialDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2196F3)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (initialDateRange != null) {
      setState(() {
        _selectedDateRange = 'Tùy chỉnh';
        _startDate = initialDateRange.start;
        _endDate = initialDateRange.end;
      });
      _filterReminders();
    } else if (_startDate == null || _endDate == null) {
      // Nếu người dùng hủy mà chưa có ngày tùy chỉnh nào được chọn trước đó
      setState(() {
        _selectedDateRange = 'Hôm nay';
      });
      _filterReminders();
    }
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isDeleteMode
              ? '${_selectedReminders.length} đã chọn'
              : 'Lịch sử dùng thuốc',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: _buildAppBarActions(),
      ),
      body: Column(
        children: [
          // Search Bar
          if (!_isDeleteMode && !_isEditMode) _buildSearchBar(),

          // Date Range Selector (MỚI)
          if (!_isDeleteMode && !_isEditMode) _buildDateRangeSelector(),

          // Select All Checkbox
          if (_isDeleteMode) _buildSelectAllCheckbox(),

          // Stats Card
          if (!_isDeleteMode && !_isEditMode && _filteredReminders.isNotEmpty)
            _buildStatsCard(),

          // Content
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : _filteredReminders.isEmpty
                ? _buildEmptyState()
                : _buildRemindersList(),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: !_isDeleteMode && !_isEditMode
                ? FloatingActionButton.extended(
              onPressed: _addReminder,
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 4,
              label: const Text(
                'Thêm mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.add),
            )
                : null,
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isDeleteMode) {
      return [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Xóa mục đã chọn',
          onPressed: _selectedReminders.isNotEmpty ? _deleteSelected : null,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Thoát chế độ xóa',
          onPressed: _toggleDeleteMode,
        ),
      ];
    }

    return [
      if (!_isEditMode)
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Chọn mục để xóa',
          onPressed: _reminders.isNotEmpty ? _toggleDeleteMode : null,
        ),
      IconButton(
        icon: Icon(_isEditMode ? Icons.close : Icons.edit_outlined),
        tooltip: _isEditMode ? 'Thoát chế độ sửa' : 'Chỉnh sửa lịch trình',
        onPressed: _reminders.isNotEmpty ? _toggleEditMode : null,
      ),
    ];
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16).copyWith(top: 8, bottom: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm thuốc, ghi chú...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CheckboxListTile(
          title: const Text(
            'Chọn tất cả',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          value: _selectAll,
          onChanged: _toggleSelectAll,
          activeColor: const Color(0xFF2196F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final todayCount = _reminders.where((r) =>
    r.time.isAfter(startOfToday) && r.time.isBefore(startOfTomorrow)
    ).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.medication,
                label: 'Tổng cộng',
                value: _reminders.length.toString(),
                color: const Color(0xFF2196F3),
              ),
              Container(height: 40, width: 1, color: Colors.grey[300]),
              _buildStatItem(
                icon: Icons.today,
                label: 'Hôm nay',
                value: todayCount.toString(),
                color: const Color(0xFF4CAF50),
              ),
              Container(height: 40, width: 1, color: Colors.grey[300]),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Tuần này',
                value: _getWeekCount().toString(),
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  int _getWeekCount() {
    final now = DateTime.now();
    // Bắt đầu từ Thứ Hai (weekday 1). Nếu là Chủ Nhật (7), lùi 6 ngày.
    final dayOfWeek = now.weekday == 7 ? 6 : now.weekday - 1;
    final weekStart = now.subtract(Duration(days: dayOfWeek));
    final startOfThisWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _reminders.where((r) => r.time.isAfter(startOfThisWeek)).length;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _searchQuery.isNotEmpty || _selectedDateRange != 'Tất cả'
                  ? Icons.search_off
                  : Icons.medication_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy kết quả'
                : (_selectedDateRange != 'Tất cả' && _selectedDateRange != 'Hôm nay'
                ? 'Không có lịch sử trong ${_selectedDateRange.toLowerCase()}'
                : 'Chưa có lịch sử nhắc nhở'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Thêm lịch trình đầu tiên của bạn',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredReminders.length,
      itemBuilder: (context, index) {
        final reminder = _filteredReminders[index];
        return _buildReminderCard(reminder, index);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, int index) {
    final isSelected = _selectedReminders.contains(reminder.id);
    final timeFormatted = DateFormat('HH:mm').format(reminder.time);
    final dateFormatted = DateFormat('dd/MM/yyyy').format(reminder.time);
    final timeAgo = _getTimeAgo(reminder.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: _isDeleteMode && isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _isDeleteMode && isSelected
                ? Border.all(color: const Color(0xFF2196F3), width: 2)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildLeadingWidget(reminder, isSelected),
            title: Text(
              reminder.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$timeFormatted • $dateFormatted',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (reminder.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.description,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: _buildTrailingWidget(reminder, isSelected),
            onTap: () => _handleTap(reminder, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(Reminder reminder, bool isSelected) {
    if (_isDeleteMode) {
      return Checkbox(
        value: isSelected,
        onChanged: (value) => _handleSelection(reminder.id, value ?? false),
        activeColor: const Color(0xFF2196F3),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.medication,
        color: Color(0xFF2196F3),
        size: 24,
      ),
    );
  }

  Widget? _buildTrailingWidget(Reminder reminder, bool isSelected) {
    if (_isDeleteMode) {
      return null;
    }

    if (_isEditMode) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.edit,
          color: Colors.green,
          size: 20,
        ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: Colors.grey[400],
    );
  }

  void _handleTap(Reminder reminder, bool isSelected) {
    if (_isDeleteMode) {
      _handleSelection(reminder.id, !isSelected);
    } else if (_isEditMode) {
      _editReminder(reminder);
    }
    // Normal mode: no action on tap
  }

  void _handleSelection(String reminderId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedReminders.add(reminderId);
      } else {
        _selectedReminders.remove(reminderId);
      }
      _selectAll = _selectedReminders.length == _filteredReminders.length && _filteredReminders.isNotEmpty;
    });
  }
}