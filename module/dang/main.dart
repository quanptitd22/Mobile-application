import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // THÊM IMPORT NÀY
import 'screens/home_screen.dart'; // Hoặc màn hình gốc của bạn

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Nhắc nhở',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      // THÊM CÁC THIẾT LẬP NÀY ĐỂ HỖ TRỢ LOCALIZATION
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Tiếng Anh
        Locale('vi', 'VN'), // Tiếng Việt (Locale bạn đang dùng)
      ],
      locale: const Locale('vi', 'VN'), // Đặt Locale mặc định là Tiếng Việt
      home: const HomeScreen(), // Thay thế bằng màn hình gốc của bạn
    );
  }
}