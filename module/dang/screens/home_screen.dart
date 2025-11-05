import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reminder_screen.dart';
import 'history_screen.dart';
import 'drawer_status_screen.dart';
import '../models/reminder_storage.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Reminder> reminders = [];
  int _currentIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    // Refresh UI periodically so that past schedule entries disappear
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() {});
    });
    // Initialize notification service and schedule existing reminders
    () async {
      try {
        await NotificationService().initialize();
        final existing = await ReminderStorage.loadReminders();
        for (var r in existing) {
          // Use service helper to schedule all times for this reminder
          await NotificationService().scheduleReminder(r);
        }
      } catch (e) {
        print('⚠️ Lỗi khi khởi tạo NotificationService: $e');
      }
    }();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .get();

    setState(() {
      reminders = snapshot.docs.map((doc) {
        final data = doc.data();

        return Reminder(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          dosage: data['dosage'] != null
              ? int.tryParse(data['dosage'].toString()) ?? 0
              : 0,
          time: data['time'] != null
              ? DateTime.parse(data['time'])
              : DateTime.now(),
          frequency: data['frequency'] ?? "Hằng ngày",
          intervalDays: data['intervalDays'] ?? 1,
          endDate: data['endDate'] != null
              ? DateTime.tryParse(data['endDate'])
              : null,
          timesPerDay: data['timesPerDay'] is List
              ? List<String>.from(data['timesPerDay'])
              : ['08:00'],
          drawer: data['drawer'] ?? 1,
        );
      }).toList();
    });
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderScreen()),
    );

    if (result != null && result is Reminder) {
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        // 1️⃣ Lưu vào Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(result.id)
            .set({
              'id': result.id,
              'title': result.title,
              'time': result.time.toIso8601String(),
              'description': result.description,
              'dosage': result.dosage,
              'frequency': result.frequency,
              'intervalDays': result.intervalDays,
              'endDate': result.endDate?.toIso8601String(),
              'timesPerDay': result.timesPerDay,
              'drawer': result.drawer,
            });

        // 2️⃣ ⭐ QUAN TRỌNG: Lưu vào Local Storage (SharedPreferences)
        await ReminderStorage.saveReminder(result);

        // Show how many pending notifications are scheduled (debug)
        try {
          final pending = await NotificationService().getPendingNotifications();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🔔 Đã lên lịch ${pending.length} thông báo cho thiết bị.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          // ignore
        }

        // 3️⃣ Cập nhật giao diện
        await _loadReminders();

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
        print('❌ Lỗi khi thêm reminder: $e');
      }
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1️⃣ Xóa từ Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .doc(reminder.id)
          .delete();

      // 2️⃣ ⭐ Xóa từ Local Storage
      await ReminderStorage.deleteReminder(reminder.id);

      // 3️⃣ Cập nhật giao diện
      await _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa: ${reminder.title}'),
            backgroundColor: Colors.orange.shade600,
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
            content: Text('❌ Lỗi khi xóa: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('❌ Lỗi khi xóa reminder: $e');
    }
  }

  // Màu sắc cho từng loại thuốc
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
            colors: [Colors.blue.shade50, Colors.white, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header với gradient
              _buildHeader(),

              // Nội dung chính
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Stats cards nằm trên header
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: _buildStatsCards(),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Lịch uống thuốc hôm nay
                            _buildTodaySchedule(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button
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
        child: GestureDetector(
          onLongPress: () async {
            try {
              await NotificationService().initialize();
              await NotificationService().showTestNotification();
              final pending = await NotificationService()
                  .getPendingNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '🔔 Test: Đã gửi thông báo thử; pending=${pending.length}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lỗi khi gửi test thông báo: $e')),
                );
              }
            }
          },
          child: FloatingActionButton(
            onPressed: _addReminder,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, size: 32),
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Drawer Menu
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white, Colors.purple.shade50],
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
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
                    style: TextStyle(color: Colors.blue.shade100, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Menu Items
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
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
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
                      Navigator.pop(context); // đóng Drawer trước
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DrawerStatusScreen()),
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

  // Header với gradient
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
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
          const SizedBox(height: 50),

          // Greeting
          const Center(
            child: Text(
              'Xin chào ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Stats cards
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '3/3',
              'Đã uống',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '85%',
              'Đã bỏ lỡ',
              Icons.cancel_outlined,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '${reminders.length}',
              'Sắp tới',
              Icons.access_time,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
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

  // Lịch uống thuốc hôm nay
  Widget _buildTodaySchedule() {
    final todaySchedules = _getTodayUpcomingSchedules();
    final displayed = todaySchedules.take(3).toList();
    final hasMore = todaySchedules.length > 3;

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (hasMore)
                TextButton(
                  onPressed: _showAllReminders,
                  child: const Text('Xem tất cả'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          todaySchedules.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: displayed.asMap().entries.map((entry) {
                    int index = entry.key;
                    final schedule = entry.value; // Map with reminder + time
                    return _buildScheduleItem(schedule, index);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  /// Trả về danh sách các occurrence (map) của lịch hôm nay mà chưa qua thời gian hiện tại
  List<Map<String, dynamic>> _getTodayUpcomingSchedules() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<Map<String, dynamic>> schedules = [];

    for (var reminder in reminders) {
      final occurrences = reminder.generateSchedule();
      for (var occ in occurrences) {
        if (occ.isBefore(todayStart) || occ.isAfter(todayEnd)) continue;
        // Keep only upcoming (not past) occurrences for today
        if (occ.isBefore(now)) continue;

        schedules.add({'reminder': reminder, 'time': occ});
      }
    }

    schedules.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );
    return schedules;
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule, int index) {
    final Reminder reminder = schedule['reminder'] as Reminder;
    final DateTime time = schedule['time'] as DateTime;
    final color = _getMedicationColor(index);

    return Dismissible(
      key: Key('${reminder.id}_${time.toIso8601String()}'),
      confirmDismiss: (direction) async {
        // For schedule occurrences we reuse same edit/delete behavior as for full reminders
        if (direction == DismissDirection.startToEnd) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReminderScreen(existingReminder: reminder),
            ),
          );

          if (result != null && result is Reminder) {
            final user = _auth.currentUser;
            if (user != null) {
              try {
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('reminders')
                    .doc(reminder.id)
                    .update({
                      'title': result.title,
                      'time': result.time.toIso8601String(),
                      'description': result.description,
                      'dosage': result.dosage,
                      'frequency': result.frequency,
                      'intervalDays': result.intervalDays,
                      'endDate': result.endDate?.toIso8601String(),
                      'timesPerDay': result.timesPerDay,
                      'drawer': result.drawer,
                    });

                await ReminderStorage.updateReminder(result);
                await _loadReminders();
              } catch (e) {
                print('❌ Lỗi khi cập nhật: $e');
              }
            }
          }
          return false;
        }

        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Bạn muốn xóa lịch nhắc này?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteReminder(reminder);
        }
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
          border: Border.all(color: color.withOpacity(0), width: 1.5),
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
        child: Row(
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
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reminder.dosage} viên',
                    style: TextStyle(
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
                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sắp tới',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReminders() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                          '${reminders.length} lịch',
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
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _buildMedicationItem(reminder, index);
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
            'Chưa có lịch nhắc nào',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Reminder reminder, int index) {
    final color = _getMedicationColor(index);

    return Dismissible(
      key: Key(reminder.id),
      confirmDismiss: (direction) async {
        // Nếu vuốt sang phải (startToEnd) - Chỉnh sửa
        if (direction == DismissDirection.startToEnd) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReminderScreen(existingReminder: reminder),
            ),
          );

          if (result != null && result is Reminder) {
            final user = _auth.currentUser;
            if (user != null) {
              try {
                // 1️⃣ Cập nhật Firestore
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('reminders')
                    .doc(reminder.id)
                    .update({
                      'title': result.title,
                      'time': result.time.toIso8601String(),
                      'description': result.description,
                      'dosage': result.dosage,
                      'frequency': result.frequency,
                      'intervalDays': result.intervalDays,
                      'endDate': result.endDate?.toIso8601String(),
                      'timesPerDay': result.timesPerDay,
                      'drawer': result.drawer,
                    });

                // 2️⃣ ⭐ Cập nhật Local Storage
                await ReminderStorage.updateReminder(result);

                // 3️⃣ Tải lại
                await _loadReminders();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã cập nhật: ${result.title}'),
                      backgroundColor: Colors.blue.shade600,
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
                      content: Text('❌ Lỗi khi cập nhật: $e'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                print('❌ Lỗi khi cập nhật: $e');
              }
            }
          }
          return false; // Không xóa item
        }

        // Nếu vuốt sang trái (endToStart) - Xóa
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận'),
              content: const Text('Bạn muốn xóa lịch nhắc này?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteReminder(reminder);
        }
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
          border: Border.all(color: color.withOpacity(0), width: 1.5),
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
        child: Row(
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
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reminder.dosage} viên',
                    style: TextStyle(
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
                  "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sắp tới',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            setState(() {
              _currentIndex = index;
            });

            // Xử lý chuyển màn hình khi nhấn vào tab
            if (index == 1) {
              // Chuyển sang HistoryScreen khi nhấn vào "Lịch uống thuốc"
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
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
                child: const Icon(Icons.notifications),
              ),
              label: 'Thông báo',
            ),
          ],
        ),
      ),
    );
  }
}
