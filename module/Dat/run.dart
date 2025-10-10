import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medireminder_app/firebase_options.dart';
import 'welcome/register_screen.dart';
import 'welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MediReminderApp());
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediReminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: const WelcomeScreen(), // 👉 mở đầu bằng Welcome
    );
  }
}
