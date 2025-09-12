import 'package:flutter/material.dart';

void main() {
  runApp(const MediReminderApp());
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediReminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(), // Menu bên trái
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
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150?img=5", // ảnh avatar
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ô tìm kiếm
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

            // Upcoming reminders
            sectionHeader("Upcoming reminders"),
            reminderTile("Morning medications", "8 AM"),
            const SizedBox(height: 10),
            reminderTile("Evening medications", "6 PM"),
            const SizedBox(height: 20),

            // Current prescriptions
            sectionHeader("Current prescriptions"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                prescriptionCard(Icons.medication, "Ibuprofen"),
                prescriptionCard(Icons.medication_liquid, "Aspirin"),
                prescriptionCard(Icons.local_hospital, "Metformin"),
              ],
            ),
            const SizedBox(height: 20),

            // Manage medications
            sectionHeader("Manage your medications"),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                manageCard(Icons.schedule, "Scheduled"),
                manageCard(Icons.history, "History"),
                manageCard(Icons.info, "Medication"),
                manageCard(Icons.notifications, "Set"),
                manageCard(Icons.check_circle, "Track"),
                manageCard(Icons.favorite, "Health status"),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  // Widget tiêu đề
  Widget sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text("View all"))
      ],
    );
  }

  // Widget reminder
  Widget reminderTile(String title, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.alarm, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15)),
          ]),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
          )
        ],
      ),
    );
  }
}

// Prescription card
class prescriptionCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const prescriptionCard(this.icon, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// Manage medications card
class manageCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const manageCard(this.icon, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          const SizedBox(height: 8),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
