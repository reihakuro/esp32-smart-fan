// lib/main.dart
import 'package:flutter/material.dart'; // Flutter framework
import 'package:shared_preferences/shared_preferences.dart'; // Lưu trữ cục bộ
import 'config/app_theme.dart'; // Import AppTheme
import 'screen/home_screen.dart'; // Import SmartFanApp

// Biến global quản lý theme
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load trạng thái Dark Mode đã lưu
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.lightTheme, 
          darkTheme: AppTheme.darkTheme,
          // Truyền hàm callback thay đổi theme vào SmartFanApp
          home: SmartFanApp(
            toggleTheme: (isDark) async {
              _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light; // Cập nhật theme
              final prefs = await SharedPreferences.getInstance(); // Lưu trạng thái
              await prefs.setBool('isDarkMode', isDark); // Lưu trạng thái
            },
          ),
        );
      },
    );
  }
}