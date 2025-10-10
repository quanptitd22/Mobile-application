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

      // 🔥 Lưu vào Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reminders')
          .add({
        'title': result.title,
        'time': result.time.toIso8601String(),
      });

      await _loadReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔥 Xóa trên Firestore
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
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              _auth.currentUser?.photoURL ?? "https://i.pravatar.cc/150?img=5",
            ),
          ),
          const SizedBox(width: 10),
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
                const ManageCard(Icons.schedule, "Scheduled"),
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
