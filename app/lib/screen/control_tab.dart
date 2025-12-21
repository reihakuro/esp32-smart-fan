// lib/screens/control_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../widgets/sensor_card.dart';

class ControlTab extends StatelessWidget {
  final bool isConnected;
  final String deviceName;
  final String temperature;
  final String humidity;
  final bool isAutoMode;
  final int fanLevel;
  
  // Các hàm callback để báo ngược lại để xử lý
  final VoidCallback onToggleMode;
  final Function(int) onFanLevelChanged;

  const ControlTab({
    Key? key,
    required this.isConnected,
    required this.deviceName,
    required this.temperature,
    required this.humidity,
    required this.isAutoMode,
    required this.fanLevel,
    required this.onToggleMode,
    required this.onFanLevelChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Trạng thái kết nối
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: isConnected ? AppTheme.success : AppTheme.error),
                const SizedBox(width: 8),
                Text(isConnected ? "Đã kết nối: $deviceName" : "Chưa kết nối",
                    style: TextStyle(
                        color: isConnected ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Card Cảm biến
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SensorCard(
                    icon: Icons.thermostat_rounded,
                    iconColor: AppTheme.primary,
                    value: temperature,
                    unit: "°C",
                    label: "Nhiệt độ"),
                Container(width: 1.5, height: 60, color: theme.dividerColor),
                SensorCard(
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blueAccent,
                    value: humidity,
                    unit: "%",
                    label: "Độ ẩm"),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Card Điều khiển
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CHẾ ĐỘ HOẠT ĐỘNG",
                            style: GoogleFonts.nunito(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(isAutoMode ? 'Tự động' : 'Thủ công',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isAutoMode ? AppTheme.primary : theme.colorScheme.onSurface)),
                      ],
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: isAutoMode,
                        onChanged: isConnected ? (val) => onToggleMode() : null,
                        activeColor: Colors.white,
                        activeTrackColor: AppTheme.primary,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.wind_power_rounded, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
                    const SizedBox(width: 8),
                    Text("TỐC ĐỘ QUẠT",
                        style: GoogleFonts.nunito(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    bool isSelected = (fanLevel == index);
                    bool isDisabled = isAutoMode || !isConnected;

                    return GestureDetector(
                      onTap: isDisabled ? null : () => onFanLevelChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : (isDisabled ? theme.scaffoldBackgroundColor : AppTheme.secondary.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
                            boxShadow: isSelected && !isDisabled
                                ? [
                                    BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5))
                                  ]
                                : []),
                        alignment: Alignment.center,
                        child: Text("$index",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : (isDisabled
                                        ? theme.colorScheme.onSurface.withOpacity(0.3)
                                        : theme.colorScheme.onSurface))),
                      ),
                    );
                  }),
                ),
                if (!isConnected)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      "* Vui lòng kết nối Bluetooth để điều khiển",
                      style: GoogleFonts.nunito(
                          color: AppTheme.error.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}