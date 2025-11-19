import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'reminder_screen.dart';
import 'history_screen.dart';
import 'drawer_status_screen.dart';
import '../models/reminder_storage.dart';
import '../services/firebase_reminder_service.dart';

// Enum cho trạng thái
enum ReminderStatus { pending, completed, skipped }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseReminderService _firebaseService = FirebaseReminderService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Danh sách lịch trình hôm nay thay vì reminders
  List<Map<String, dynamic>> _todaySchedules = [];
  final Map<String, ReminderStatus> _statuses = {};

  int _currentIndex = 0;
  bool _isLoading = false;

  // 📊 Biến lưu thống kê
  Map<String, int> _statistics = {
    'completed': 0,
    'skipped': 0,
    'pending': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTodaySchedules();
    _loadStatistics();
  }

  /// 📅 Load lịch trình hôm nay
  Future<void> _loadTodaySchedules() async {
    setState(() => _isLoading = true);

    try {
      // Đồng bộ từ Firebase trước
      await _firebaseService.syncFromFirebaseToLocal();

      // Lấy tất cả lịch trình
      final allSchedules = await ReminderStorage.getAllSchedules();

      // Lọc chỉ lấy lịch hôm nay
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todaySchedules = allSchedules.where((schedule) {
        final time = schedule['time'] as DateTime;
        return time.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            time.isBefore(endOfDay);
      }).toList();

      // Sắp xếp theo thời gian
      todaySchedules.sort((a, b) =>
          (a['time'] as DateTime).compareTo(b['time'] as DateTime));

      setState(() {
        _todaySchedules = todaySchedules;
      });

      // Load trạng thái
      await _loadStatusesFromFirebase();

      print("✅ Đã tải ${_todaySchedules.length} lịch trình hôm nay");
    } catch (e) {
      print("❌ Lỗi khi tải lịch trình hôm nay: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📥 Tải trạng thái từ Firebase
  Future<void> _loadStatusesFromFirebase() async {
    try {
      final statuses = await _firebaseService.getAllReminderStatuses();
      setState(() {
        _statuses.clear();
        for (var entry in statuses.entries) {
          if (entry.value == 'completed') {
            _statuses[entry.key] = ReminderStatus.completed;
          } else if (entry.value == 'skipped') {
            _statuses[entry.key] = ReminderStatus.skipped;
          } else {
            _statuses[entry.key] = ReminderStatus.pending;
          }
        }
      });
    } catch (e) {
      print('⚠️ Lỗi khi tải trạng thái: $e');
    }
  }

  /// 📊 Tải thống kê từ Firebase
  Future<void> _loadStatistics() async {
    try {
      final allSchedules = await ReminderStorage.getAllSchedules();
      final statuses = await _firebaseService.getAllReminderStatuses();

      int completed = 0;
      int skipped = 0;
      int pending = 0;

      for (var schedule in allSchedules) {
        final time = schedule['time'] as DateTime;
        final id = '${schedule['title']}_${time.toIso8601String()}';
        final status = statuses[id] ?? 'pending';

        if (status == 'completed') {
          completed++;
        } else if (status == 'skipped') {
          skipped++;
        } else {
          pending++;
        }
      }

      setState(() {
        _statistics = {
          'completed': completed,
          'skipped': skipped,
          'pending': pending,
          'total': allSchedules.length,
        };
      });
    } catch (e) {
      print("❌ Lỗi khi tải thống kê: $e");
    }
  }

  /// ✅ Thêm reminder mới
  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderScreen()),
    );

    if (result != null && result is Reminder) {
      try {
        await ReminderStorage.saveReminder(result);
        await _loadTodaySchedules();
        await _loadStatistics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Đã thêm: ${result.title}'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: $e'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 🛠️ Chỉnh sửa lịch trình
  Future<void> _editSchedule(Map<String, dynamic> schedule) async {
    final String? reminderId = schedule['reminderId'];

    if (reminderId == null) {
      _showErrorSnackBar('Lỗi: Không tìm thấy ID của lịch trình');
      return;
    }

    final reminder = await ReminderStorage.getReminderById(reminderId);

    if (reminder == null) {
      _showErrorSnackBar('Lỗi: Không thể tải lịch trình');
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
      await _loadTodaySchedules();
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật: ${updatedReminder.title}'),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// 🗑️ Xóa lịch trình (chỉ xóa 1 lần cụ thể hoặc toàn bộ)
  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
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
                leading: const Icon(Icons.delete_outline, color: Colors.orange),
                title: const Text('Xóa lịch trình hôm nay'),
                subtitle: Text('Chỉ xóa lịch ${DateFormat('HH:mm').format(
                    schedule['time'])}'),
                onTap: () async {
                  Navigator.pop(context);
                  // Xóa trạng thái của lịch trình này
                  final time = schedule['time'] as DateTime;
                  final id = '${schedule['title']}_${time.toIso8601String()}';

                  try {
                    await _firebaseService.updateReminderStatus(id, 'deleted');
                    await _loadTodaySchedules();
                    await _loadStatistics();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Đã xóa lịch trình ${DateFormat(
                              'HH:mm').format(time)}'),
                          backgroundColor: Colors.orange.shade600,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    print("❌ Lỗi khi xóa lịch trình: $e");
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                    Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Xóa toàn bộ thuốc này'),
                subtitle: const Text('Xóa tất cả lịch trình của thuốc này'),
                onTap: () async {
                  Navigator.pop(context);
                  final reminderId = schedule['reminderId'];

                  if (reminderId != null) {
                    try {
                      await ReminderStorage.deleteReminder(reminderId);
                      await _loadTodaySchedules();
                      await _loadStatistics();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✅ Đã xóa toàn bộ: ${schedule['title']}'),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      print("❌ Lỗi khi xóa thuốc: $e");
                    }
                  }
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

  /// ✅ Đánh dấu đã uống
  Future<void> _markAsCompleted(Map<String, dynamic> schedule) async {
    final time = schedule['time'] as DateTime;
    final id = '${schedule['title']}_${time.toIso8601String()}';

    setState(() => _statuses[id] = ReminderStatus.completed);

    try {
      await _firebaseService.updateReminderStatus(id, 'completed');
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💊 Đã uống: ${schedule['title']}'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Lỗi khi cập nhật trạng thái: $e');
    }
  }

  /// ⏭️ Đánh dấu bỏ qua
  Future<void> _markAsSkipped(Map<String, dynamic> schedule) async {
    final time = schedule['time'] as DateTime;
    final id = '${schedule['title']}_${time.toIso8601String()}';

    setState(() => _statuses[id] = ReminderStatus.skipped);

    try {
      await _firebaseService.updateReminderStatus(id, 'skipped');
      await _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏭️ Đã bỏ qua: ${schedule['title']}'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('⚠️ Lỗi khi cập nhật trạng thái: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getMedicationColor(int index) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadTodaySchedules();
                    await _loadStatistics();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          _buildTodaySchedule(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.purple.shade600],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addReminder,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                      _auth.currentUser?.photoURL ??
                          "https://i.pravatar.cc/150?img=5",
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _auth.currentUser?.displayName ?? 'Người dùng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _auth.currentUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.blue.shade100,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildDrawerItem(
                    icon: Icons.schedule,
                    title: 'Đặt lịch uống thuốc',
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade500, Colors.purple.shade600],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _addReminder();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Lịch sử',
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HistoryScreen()),
                      ).then((_) {
                        _loadTodaySchedules();
                        _loadStatistics();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: 'Trạng thái hộp thuốc',
                    gradient: LinearGradient(
                      colors: [Colors.greenAccent, Colors.green],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DrawerStatusScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 400),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Đăng xuất',
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    onTap: () async {
                      await _auth.signOut();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.purple.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              const Text(
                'MediReminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ??
                      "https://www.cambridgebiotherapies.com/wp-content/uploads/what-is-medication-management.jpg",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final completed = _statistics['completed'] ?? 0;
    final skipped = _statistics['skipped'] ?? 0;
    final pending = _statistics['pending'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '$completed',
              'Đã uống',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '$skipped',
              'Đã bỏ lỡ',
              Icons.cancel_outlined,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '$pending',
              'Sắp tới',
              Icons.access_time,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(1),
            blurRadius: 17,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    // Lọc chỉ lấy 3 lịch trình đầu tiên
    final displayedSchedules = _todaySchedules.take(3).toList();
    final hasMore = _todaySchedules.length > 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch uống thuốc hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasMore)
                TextButton(
                  onPressed: _showAllSchedules,
                  child: const Text('Xem tất cả'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _todaySchedules.isEmpty
              ? _buildEmptyState()
              : Column(
            children: displayedSchedules
                .asMap()
                .entries
                .map((entry) {
              int index = entry.key;
              var schedule = entry.value;
              return _buildScheduleItem(schedule, index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAllSchedules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tất cả lịch trình hôm nay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_todaySchedules.length} lịch',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _todaySchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _todaySchedules[index];
                      return _buildScheduleItem(schedule, index);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch nhắc nào hôm nay',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule, int index) {
    final color = _getMedicationColor(index);
    final time = schedule['time'] as DateTime;
    final id = '${schedule['title']}_${time.toIso8601String()}';
    final status = _statuses[id] ?? ReminderStatus.pending;
    final isInPast = time.isBefore(DateTime.now());

    // Kiểm tra nếu đã bị xóa (soft delete)
    if (status.name == 'deleted') {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Vuốt sang phải - Chỉnh sửa
          await _editSchedule(schedule);
          return false;
        }

        if (direction == DismissDirection.endToStart) {
          // Vuốt sang trái - Hiển thị menu xóa
          await _deleteSchedule(schedule);
          return false;
        }

        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.purple.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule['title'] ?? 'Không rõ tên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${schedule['dosage']} viên',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == ReminderStatus.completed
                            ? Colors.green.withOpacity(0.15)
                            : status == ReminderStatus.skipped
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status == ReminderStatus.completed
                            ? 'Đã uống'
                            : status == ReminderStatus.skipped
                            ? 'Đã bỏ qua'
                            : isInPast
                            ? 'Chờ uống'
                            : 'Sắp tới',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: status == ReminderStatus.completed
                              ? Colors.green.shade600
                              : status == ReminderStatus.skipped
                              ? Colors.orange.shade600
                              : Colors.blue.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Hiển thị nút hành động nếu lịch trong quá khứ và chưa được đánh dấu
            if (isInPast && status == ReminderStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markAsSkipped(schedule),
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
                      onPressed: () => _markAsCompleted(schedule),
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
            ] else
              if (!isInPast) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chưa đến giờ uống thuốc',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // TAB 0 → HOME
            if (index == 0) {
              setState(() {
                _currentIndex = 0;
              });
              return;
            }

            // TAB 1 → HISTORY
            if (index == 1) {
              setState(() {
                _currentIndex = 1;
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              ).then((_) {
                // Reset tab sau khi quay về
                setState(() {
                  _currentIndex = 0;
                });
                _loadTodaySchedules();
                _loadStatistics();
              });

              return;
            }

            // TAB 2 → DRAWER STATUS
            if (index == 2) {
              setState(() {
                _currentIndex = 2;
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DrawerStatusScreen(),
                ),
              ).then((_) {
                // Reset tab về home
                setState(() {
                  _currentIndex = 0;
                });
              });

              return;
            }
          },
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_edu_outlined),
              ),
              label: 'Lịch uống thuốc',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2
                      ? Colors.blue.shade50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              label: 'Trạng thái hộp thuốc',
            ),
          ],
        ),
      ),
    );
  }
}