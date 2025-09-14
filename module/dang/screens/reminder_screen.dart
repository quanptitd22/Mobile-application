import 'package:flutter/material.dart';
import '../models/reminder_storage.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _medicineController =
  TextEditingController(text: "Ibuprofen");
  final TextEditingController _amountController =
  TextEditingController(text: "2");
  final TextEditingController _durationController =
  TextEditingController(text: "10");

  String unit = "Capsule";
  bool afterMeal = true;
  bool beforeMeal = false;
  String durationUnit = "Days";

  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _medicineController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_medicineController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _durationController.text.isEmpty ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final reminder = Reminder(
      id: DateTime.now().toIso8601String(),
      title: "${_medicineController.text} (${_amountController.text} $unit)",
      time: scheduledTime,
    );

    // 1. Lưu vào storage
    await ReminderStorage.saveReminder(reminder);

    // 2. Đặt thông báo
    await NotificationService().scheduleNotification(
      id: reminder.id.hashCode,
      title: "Nhắc nhở uống thuốc",
      body:
      "Đến giờ uống ${_medicineController.text} (${_amountController.text} $unit) rồi!",
      scheduledTime: scheduledTime,
    );

    // 3. Hiện dialog thành công -> OK -> trả reminder về HomeScreen
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Thành công"),
          content: const Text("Đã thêm thuốc thành công!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // đóng dialog
                Navigator.of(context).pop(reminder); // trả reminder về Home
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Set Medication Reminder",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Time Picker
            Center(
              child: InkWell(
                onTap: _pickTime,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedTime == null
                        ? "SET"
                        : "${_selectedTime!.hour.toString().padLeft(2, '0')} : ${_selectedTime!.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Medicine Name
            const Text("Tên thuốc",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _medicineController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Medicine name",
              ),
            ),
            const SizedBox(height: 20),

            /// Amount + Dropdown
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField(
                    value: unit,
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
            const Text("Thời điểm uống",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Checkbox(
                  value: afterMeal,
                  onChanged: (val) {
                    setState(() {
                      afterMeal = val!;
                      if (afterMeal) beforeMeal = false;
                    });
                  },
                ),
                const Text("After meal"),
                Checkbox(
                  value: beforeMeal,
                  onChanged: (val) {
                    setState(() {
                      beforeMeal = val!;
                      if (beforeMeal) afterMeal = false;
                    });
                  },
                ),
                const Text("Before meal"),
              ],
            ),
            const SizedBox(height: 20),

            /// Duration
            const Text("Thời gian dùng",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField(
                    value: durationUnit,
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

            /// Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveReminder,
                child: const Text(
                  "Save Reminder",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
