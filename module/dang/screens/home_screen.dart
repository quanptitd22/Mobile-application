// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../widgets/manage_card.dart';
// import '../widgets/prescription_card.dart';
// import '../widgets/reminder_tile.dart';
// import 'reminder_screen.dart';
// import 'history_screen.dart';
// import '../models/reminder_storage.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   List<Reminder> reminders = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadReminders();
//   }
//
//   Future<void> _loadReminders() async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final snapshot = await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('reminders')
//         .get();
//
//     setState(() {
//       reminders = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//
//         return Reminder(
//           id: doc.id,
//           title: data['title'] ?? '',
//           description: data['description'] ?? '',
//           dosage: data['dosage'] != null
//               ? int.tryParse(data['dosage'].toString()) ?? 0
//               : 0,
//           time: data['time'] != null
//               ? DateTime.parse(data['time'])
//               : DateTime.now(),
//           frequency: data['frequency'] ?? "Hằng ngày",
//           intervalDays: data['intervalDays'] ?? 1,
//           endDate: data['endDate'] != null
//               ? DateTime.tryParse(data['endDate'])
//               : null,
//         );
//       }).toList();
//     });
//
//
//   }
//
//   Future<void> _addReminder() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const ReminderScreen()),
//     );
//
//     if (result != null && result is Reminder) {
//       final user = _auth.currentUser;
//       if (user == null) return;
//
//       // 🔥 Lưu vào Firestore
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('reminders')
//           .add({
//         'title': result.title,
//         'time': result.time.toIso8601String(),
//       });
//
//       await _loadReminders();
//     }
//   }
//
//   Future<void> _deleteReminder(Reminder reminder) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     // 🔥 Xóa trên Firestore
//     await _firestore
//         .collection('users')
//         .doc(user.uid)
//         .collection('reminders')
//         .doc(reminder.id)
//         .delete();
//
//     await _loadReminders();
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Đã xóa reminder")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const Drawer(),
//       appBar: AppBar(
//         title: const Text(
//           "MediReminder",
//           style: TextStyle(color: Colors.black),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.black),
//           onPressed: () {},
//         ),
//         actions: [
//           CircleAvatar(
//             backgroundImage: NetworkImage(
//               _auth.currentUser?.photoURL ?? "https://i.pravatar.cc/150?img=5",
//             ),
//           ),
//           const SizedBox(width: 10),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🔍 Search
//             TextField(
//               decoration: InputDecoration(
//                 hintText: "Search medications, schedules...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // ⏰ Upcoming reminders
//             sectionHeader("Upcoming reminders"),
//             reminders.isEmpty
//                 ? const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(8.0),
//                 child: Text("No reminders yet"),
//               ),
//             )
//                 : Column(
//               children: reminders.map((reminder) {
//                 return Dismissible(
//                   key: Key(reminder.id),
//                   onDismissed: (_) => _deleteReminder(reminder),
//                   background: Container(color: Colors.red),
//                   child: ReminderTile(
//                     title: reminder.title,
//                     time:
//                     "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}",
//                   ),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 20),
//
//
//
//
//
//             // 📋 Manage medications
//             sectionHeader("Application Features"),
//             const SizedBox(height: 10),
//             GridView.count(
//               crossAxisCount: 3,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               children: [
//                 // const ManageCard(Icons.schedule, "Scheduled"),
//                 GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const HistoryScreen()),
//                     );
//                   },
//                   child: const ManageCard(Icons.history, "History"),
//                 ),
//                 // const ManageCard(Icons.info, "Medication"),
//                 GestureDetector(
//                   onTap: _addReminder,
//                   child: const ManageCard(Icons.notifications, "Set"),
//                 ),
//                 const ManageCard(Icons.check_circle, "Track"),
//                 // const ManageCard(Icons.favorite, "Health status"),
//               ],
//             )
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//     );
//   }
//
//   Widget sectionHeader(String title) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         TextButton(onPressed: () {}, child: const Text("View all"))
//       ],
//     );
//   }
// }


// -----------------------------------------------------------------------------------------------------
// code giao diện mới

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/manage_card.dart';
import '../widgets/prescription_card.dart';
import '../widgets/reminder_tile.dart';
import 'reminder_screen.dart';
import 'history_screen.dart';
import '../models/reminder_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Reminder> reminders = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReminders();
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
        final data = doc.data() as Map<String, dynamic>;

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

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .add({
        'title': result.title,
        'time': result.time.toIso8601String(),
        'description': result.description,
        'dosage': result.dosage,
        'frequency': result.frequency,
        'intervalDays': result.intervalDays,
        'endDate': result.endDate?.toIso8601String(),
      });

      await _loadReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reminders')
        .doc(reminder.id)
        .delete();

    await _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa reminder")),
      );
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

                            // Feature cards
                            _buildFeatureCards(),
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
        child: FloatingActionButton(
          onPressed: _addReminder,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 32),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
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
              const Icon(Icons.menu, color: Colors.white, size: 28),
              const Text(
                'MediReminder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ?? "https://i.pravatar.cc/150?img=5",
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Greeting
          const Text(
            'Xin chào! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đừng quên uống thuốc đúng giờ nhé',
            style: TextStyle(
              color: Colors.blue.shade100,
              fontSize: 16,
            ),
          ),
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
          Expanded(child: _buildStatCard('3/3', 'Hôm nay', Icons.check_circle, Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('85%', 'Tuần này', Icons.trending_up, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('${reminders.length}', 'Sắp tới', Icons.access_time, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
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
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Lịch uống thuốc hôm nay
  Widget _buildTodaySchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
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
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          reminders.isEmpty
              ? _buildEmptyState()
              : Column(
            children: reminders.asMap().entries.map((entry) {
              int index = entry.key;
              Reminder reminder = entry.value;
              return _buildMedicationItem(reminder, index);
            }).toList(),
          ),
        ],
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
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(Reminder reminder, int index) {
    final color = _getMedicationColor(index);

    return Dismissible(
      key: Key(reminder.id),
      onDismissed: (_) => _deleteReminder(reminder),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon thuốc
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

            // Thông tin thuốc
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Thời gian
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
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Feature cards
  Widget _buildFeatureCards() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            'Lịch sử',
            Icons.history,
            LinearGradient(colors: [Colors.blue.shade500, Colors.blue.shade600]),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFeatureCard(
            'Đặt nhắc',
            Icons.notifications,
            LinearGradient(colors: [Colors.purple.shade500, Colors.purple.shade600]),
            _addReminder,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFeatureCard(
            'Theo dõi',
            Icons.check_circle,
            LinearGradient(colors: [Colors.green.shade500, Colors.green.shade600]),
                () {},
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String label, IconData icon, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation
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
                  color: _currentIndex == 0 ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today),
              ),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication),
              ),
              label: 'Thuốc',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.blue.shade50 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person),
              ),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}