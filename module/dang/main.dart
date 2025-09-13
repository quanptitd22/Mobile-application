import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
