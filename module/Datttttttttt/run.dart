import 'package:flutter/material.dart';
import 'front_end/welcome_screen.dart';

void main() {
  runApp(const MediReminderApp());
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhắc nhở uống thuốc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomeScreen(), // mở đầu bằng Welcome
    );
  }
}
