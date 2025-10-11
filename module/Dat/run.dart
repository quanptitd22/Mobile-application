import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome/login_screen.dart';
import 'welcome/register_screen.dart';
import '../dang/screens/home_screen.dart'; // màn hình chính sau khi đăng nhập
import 'welcome/welcome_screen.dart';
import '../dang/services/firebase_reminder_service.dart';
import '../dang/models/reminder_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp();

  // ✅ Tạo instance của service
  final firebaseService = FirebaseReminderService();

  try {
    // ✅ Đồng bộ dữ liệu từ Firestore xuống local
    await firebaseService.syncFromFirebaseToLocal();
    print("✅ Đồng bộ dữ liệu thành công!");
  } catch (e) {
    print("❌ Lỗi khi đồng bộ dữ liệu: $e");
  }

  // ✅ Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medication Reminder',
      initialRoute: '/welcome', // Màn hình khởi đầu
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}