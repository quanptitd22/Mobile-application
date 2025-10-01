import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_storage.dart';

class HistoryScreen extends StatefulWidget {
  // Chuyển thành StatefulWidget để quản lý trạng thái
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<List<Reminder>>? _remindersFuture; // Lưu trữ future để có thể refresh

  @override
  void initState() {
    super.initState();
    _loadReminders(); // Tải dữ liệu khi widget được khởi tạo
  }

  Future<void> _loadReminders() async {
    setState(() {
      _remindersFuture = ReminderStorage.loadReminders();
    });
  }

  Future<void> _clearHistory() async {
    // Hiển thị hộp thoại xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa toàn bộ lịch sử dùng thuốc không?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Hủy
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Xác nhận
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ReminderStorage.clearAllReminders(); // Gọi hàm xóa từ storage
      _loadReminders(); // Tải lại danh sách sau khi xóa
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử dùng thuốc"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearHistory, // Gọi hàm xóa khi nhấn nút
            tooltip: 'Xóa tất cả lịch sử',
          ),
        ],
      ),
      body: FutureBuilder<List<Reminder>>(
        future: _remindersFuture, // Sử dụng future đã lưu
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) { // Thêm xử lý lỗi
            return Center(
              child: Text(
                "Lỗi khi tải lịch sử: ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có lịch sử nhắc nhở",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final reminders = snapshot.data!;

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];
              final timeFormatted =
              DateFormat("HH:mm dd/MM/yyyy").format(r.time);

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.blue),
                  title: Text(
                    r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    timeFormatted,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
