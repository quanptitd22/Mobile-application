import 'package:flutter/material.dart';

void main() {
  runApp(const MediPromptApp());
}

class MediPromptApp extends StatelessWidget {
  const MediPromptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MediPrompt Notifications",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NotificationsScreen(),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// Title
            const Text(
              "Notifications",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// Medication cards
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationCard(
                      "Aspirin", "100mg", "8:00 AM"),
                  _buildNotificationCard(
                      "Ibuprofen", "200mg", "12:00 PM"),
                  _buildNotificationCard(
                      "Metformin", "500mg", "6:00 PM"),
                ],
              ),
            ),
          ],
        ),
      ),

      /// Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: ""),
        ],
      ),
    );
  }

  /// Notification card widget
  Widget _buildNotificationCard(
      String medication, String dosage, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Medication: $medication",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          Text("Dosage: $dosage"),
          Text("Time: $time"),
          const SizedBox(height: 10),

          /// Buttons Edit + Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[300],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text("Edit"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text("Delete"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
