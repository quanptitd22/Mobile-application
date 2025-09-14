import 'package:flutter/material.dart';
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
  List<Reminder> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final data = await ReminderStorage.loadReminders();
    setState(() {
      reminders = data;
    });
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReminderScreen()),
    );

    if (result != null && result is Reminder) {
      // 👉 Lưu reminder (dùng ReminderStorage luôn)
      await ReminderStorage.saveReminder(result);
      await _loadReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    await ReminderStorage.deleteReminder(reminder.id);
    await _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa reminder")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(),
      appBar: AppBar(
        title: const Text(
          "MediReminder",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: const [
          CircleAvatar(
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search
            TextField(
              decoration: InputDecoration(
                hintText: "Search medications, schedules...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),

            // ⏰ Upcoming reminders
            sectionHeader("Upcoming reminders"),
            reminders.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("No reminders yet"),
              ),
            )
                : Column(
              children: reminders.map((reminder) {
                return Dismissible(
                  key: Key(reminder.id),
                  onDismissed: (_) => _deleteReminder(reminder),
                  background: Container(color: Colors.red),
                  child: ReminderTile(
                    title: reminder.title,
                    time:
                    "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}",
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 💊 Current prescriptions
            sectionHeader("Current prescriptions"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                PrescriptionCard(Icons.medication, "Ibuprofen"),
                PrescriptionCard(Icons.medication_liquid, "Aspirin"),
                PrescriptionCard(Icons.local_hospital, "Metformin"),
              ],
            ),
            const SizedBox(height: 20),

            // 📋 Manage medications
            sectionHeader("Manage your medications"),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                // Scheduled
                GestureDetector(
                  onTap: () {
                    // 👉 Có thể mở màn hình quản lý Scheduled
                  },
                  child: const ManageCard(Icons.schedule, "Scheduled"),
                ),

                // History
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()),
                    );
                  },
                  child: const ManageCard(Icons.history, "History"),
                ),

                const ManageCard(Icons.info, "Medication"),

                // 👉 Nhấn vào đây để mở màn hình setup
                GestureDetector(
                  onTap: _addReminder,
                  child: const ManageCard(Icons.notifications, "Set"),
                ),

                const ManageCard(Icons.check_circle, "Track"),
                const ManageCard(Icons.favorite, "Health status"),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text("View all"))
      ],
    );
  }
}
