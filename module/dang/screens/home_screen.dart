import 'package:flutter/material.dart';
import '../widgets/manage_card.dart';
import '../widgets/prescription_card.dart';
import '../widgets/reminder_tile.dart';
import 'reminder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // Search
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
            const ReminderTile("Morning medications", "8 AM"),
            const SizedBox(height: 10),
            const ReminderTile("Evening medications", "6 PM"),
            const SizedBox(height: 20),

            // Current prescriptions
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

            // Manage medications
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
                const ManageCard(Icons.history, "History"),
                const ManageCard(Icons.info, "Medication"),

                // 👉 Nhấn vào đây để mở màn hình setup
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReminderScreen(),
                      ),
                    );
                  },
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
