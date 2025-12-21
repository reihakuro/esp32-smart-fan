// lib/screens/settings_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class SettingsTab extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsTab({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tuỳ chỉnh giao diện",
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Chế độ Tối", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Giao diện nền tối bảo vệ mắt",
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.indigoAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.indigoAccent),
                  ),
                  value: isDarkMode,
                  activeColor: AppTheme.primary,
                  onChanged: onThemeChanged, // Gọi hàm callback
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text("Thông tin ứng dụng",
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration:
                    BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.green),
              ),
              title: const Text("Phiên bản", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text("0.3.8",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}