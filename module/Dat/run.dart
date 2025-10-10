import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome/login_screen.dart';
import 'welcome/register_screen.dart';
import '../dang/screens/home_screen.dart'; // màn hình chính sau khi đăng nhập
import 'welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // quan trọng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medication Reminder',
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
