import 'package:flutter/material.dart';

// Đường dẫn này có thể cần điều chỉnh tùy thuộc vào cấu trúc thư mục của bạn
import 'package:your_app_name/screens/history_screen.dart'; // Giả sử 'your_app_name' là tên package của bạn

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng của tôi', // Bạn có thể thay đổi tiêu đề này
      theme: ThemeData(
        primarySwatch: Colors.blue, // Bạn có thể tùy chỉnh theme
      ),
      home: const HistoryScreen(), // Đặt HistoryScreen làm màn hình chính
    );
  }
}
