// lib/screens/devices_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../config/app_theme.dart';

class DevicesTab extends StatelessWidget {
  final List<BluetoothDevice> devicesList;
  final BluetoothDevice? connectedDevice;
  final bool isConnecting;
  
  // Callbacks
  final Function(BluetoothDevice) onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;

  const DevicesTab({
    Key? key,
    required this.devicesList,
    required this.connectedDevice,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Thiết bị khả dụng",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                onPressed: onRefresh,
                style: IconButton.styleFrom(backgroundColor: AppTheme.secondary.withOpacity(0.2)),
              )
            ],
          ),
        ),
        Expanded(
          child: devicesList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching_rounded,
                          size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text("Không tìm thấy thiết bị nào",
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: FlutterBluetoothSerial.instance.openSettings,
                        child: const Text("Mở cài đặt Bluetooth",
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devicesList[index];
                    bool isDevConnected = (connectedDevice?.address == device.address);

                    return Container(
                      decoration: BoxDecoration(
                          color: isDevConnected ? AppTheme.primary.withOpacity(0.1) : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDevConnected ? AppTheme.primary : Colors.transparent),
                          boxShadow: [
                            if (!isDevConnected)
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                          ]),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDevConnected ? AppTheme.primary : theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.bluetooth_rounded,
                              color: isDevConnected ? Colors.white : AppTheme.secondary),
                        ),
                        title: Text(device.name ?? "Không tên",
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        subtitle: Text(device.address,
                            style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                        trailing: isDevConnected
                            ? TextButton.icon(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text("Ngắt kết nối"),
                                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                onPressed: onDisconnect,
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                onPressed: isConnecting ? null : () => onConnect(device),
                                child: Text(isConnecting ? "..." : "Kết nối"),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}