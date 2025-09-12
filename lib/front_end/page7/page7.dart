import 'package:flutter/material.dart';

void main() {
  runApp(const MediPromptApp());
}

class MediPromptApp extends StatelessWidget {
  const MediPromptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MediPrompt",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MedicationScheduleScreen(),
    );
  }
}

class MedicationScheduleScreen extends StatelessWidget {
  const MedicationScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.lock, size: 20, color: Colors.black),
            SizedBox(width: 6),
            Text(
              "MediPrompt",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Medication Schedule",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text("Add Medication"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Medication list
            Expanded(
              child: ListView(
                children: [
                  _buildMedicationCard(
                    "Atorvastatin",
                    "Dosage: 10mg, once daily",
                    "Instructions: Take with dinner",
                  ),
                  _buildMedicationCard(
                    "Lisinopril",
                    "Dosage: 20mg, twice daily",
                    "Instructions: Take with water",
                  ),
                  _buildMedicationCard(
                    "Metformin",
                    "Dosage: 500mg, once daily",
                    "Instructions: Take with food",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Medication card widget
  Widget _buildMedicationCard(
      String name, String dosage, String instructions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text(dosage),
          Text(instructions),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black12),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text("Edit"),
            ),
          ),
        ],
      ),
    );
  }
}
