import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome/login_screen.dart';
import 'welcome/register_screen.dart';
import '../dang/screens/home_screen.dart';
import 'welcome/welcome_screen.dart';
import '../dang/services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp();

  await NotificationService().initialize();
  print('🔔 Notification Service đã được khởi tạo');

  // ✅ Chạy ứng dụng
  runApp(const MyApp());
}
//hehe
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
