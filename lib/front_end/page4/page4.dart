import 'package:flutter/material.dart';

void main() {
  runApp(const MedicationReminderApp());
}

class MedicationReminderApp extends StatelessWidget {
  const MedicationReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MedicationReminderScreen(),
    );
  }
}

class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() =>
      _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  String medicineName = "Ibuprofen";
  int amount = 2;
  String unit = "Capsule";
  bool afterMeal = true;
  bool beforeMeal = false;
  int duration = 10;
  String durationUnit = "Days";
  int selectedIcon = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          "Set Medication Reminder",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Time Picker Mockup
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "07 : 00",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Medicine Name
            const Text("Pain Relief",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Medicine name",
              ),
              controller: TextEditingController(text: medicineName),
            ),
            const SizedBox(height: 20),

            /// Amount + Dropdown
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller:
                    TextEditingController(text: amount.toString()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ["Capsule", "Tablet", "ml"]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        unit = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Timing
            const Text("Timing",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Checkbox(
                  value: afterMeal,
                  onChanged: (val) {
                    setState(() => afterMeal = val!);
                  },
                ),
                const Text("After meal"),
                Checkbox(
                  value: beforeMeal,
                  onChanged: (val) {
                    setState(() => beforeMeal = val!);
                  },
                ),
                const Text("Before meal"),
              ],
            ),
            const SizedBox(height: 20),

            /// Duration
            const Text("Duration",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller:
                    TextEditingController(text: duration.toString()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField(
                    initialValue: durationUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ["Days", "Weeks", "Months"]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        durationUnit = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Choose icon
            const Text("Choose icon",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIcon = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedIcon == index
                          ? Colors.blue[300]
                          : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color:
                      selectedIcon == index ? Colors.white : Colors.black,
                      size: 30,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),

            /// Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () {},
                child: const Text(
                  "Save Reminder",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}
