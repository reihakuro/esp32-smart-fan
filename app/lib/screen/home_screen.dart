// lib/screens/home_screen.dart
// khung chính app
// file để chuyên xử lý luồng dữ liệu và cập nhật trạng thái đẩy lên widget 
// xử lý bluetooth
import 'dart:async'; // for Timer
import 'dart:convert'; // for utf8 encoding, giao tiếp với dữ liệu từ ESP32
import 'dart:typed_data'; // for Uint8List
import 'package:flutter/material.dart'; // Flutter framework
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Thư viện định dạng thời gian
import 'package:google_fonts/google_fonts.dart'; // Thư viện font chữ

import '../config/app_theme.dart';
import 'control_tab.dart'; // Import ControlTab
import 'devices_tab.dart'; // Import DevicesTab
import 'settings_tab.dart'; // Import SettingsTab

class SmartFanApp extends StatefulWidget {
  final Function(bool) toggleTheme; // Nhận hàm đổi theme từ main
  const SmartFanApp({Key? key, required this.toggleTheme}) : super(key: key);

  @override // Tạo trạng thái cho widget
  _SmartFanAppState createState() => _SmartFanAppState();
}

class _SmartFanAppState extends State<SmartFanApp> with SingleTickerProviderStateMixin {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  bool isConnecting = false;
  bool get isConnected => (connection?.isConnected ?? false);

  String _temperature = "--";
  String _humidity = "--";
  bool _isAutoMode = false;
  int _fanLevel = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState(); // Khởi tạo trạng thái
    _tabController = TabController(length: 3, vsync: this);
    _requestPermissions();
    _loadLastKnownState();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _disconnect();
        } else {
          _getPairedDevices();
        }
      });
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    _getPairedDevices();
  }

  Future<void> _getPairedDevices() async {
    List<BluetoothDevice> list = [];
    try {
      list = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Lỗi: $e");
    }
    if (!mounted) return;
    setState(() {
      _devicesList = list;
    });
  }

  void _connect(BluetoothDevice device) async {
    setState(() => isConnecting = true);
    if (connection != null) {
      await connection!.close();
    }

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _tabController.animateTo(0);

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (mounted) {
          setState(() {
            _connectedDevice = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã ngắt kết nối thiết bị")),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi kết nối: $e")),
        );
      }
    }
    setState(() => isConnecting = false);
  }

  void _disconnect() async {
    await connection?.close();
    setState(() {
      _connectedDevice = null;
    });
  }

  String _buffer = "";
  void _onDataReceived(Uint8List data) {
    String incoming = utf8.decode(data);
    _buffer += incoming;

    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      _buffer = lines.last;

      for (int i = 0; i < lines.length - 1; i++) {
        _processLine(lines[i].trim());
      }
    }
  }

  void _processLine(String line) {
    bool hasChange = false;

    if (line.startsWith("Temperature:")) {
      String val = line.split(":")[1].trim();
      if (val != _temperature) {
        _temperature = val;
        hasChange = true;
      }
    } else if (line.startsWith("Humidity:")) {
      String val = line.split(":")[1].trim();
      if (val != _humidity) {
        _humidity = val;
        hasChange = true;
      }
    } else if (line.startsWith("POWER:")) {
      int stateVal = int.tryParse(line.split(":")[1].trim()) ?? 0;
      bool newState = (stateVal == 1);
      if (newState != _isAutoMode) {
        _isAutoMode = newState;
        hasChange = true;
      }
    }

    if (hasChange && mounted) {
      setState(() {});
      _saveDataBackground();
    }
  }

  void _saveDataBackground() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_temp', _temperature);
    await prefs.setString('last_hum', _humidity);

    List<String> history = prefs.getStringList('sensor_history') ?? [];
    String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String entry = "$timestamp | $_temperature°C | $_humidity%";
    history.insert(0, entry);
    if (history.length > 100) history.removeLast();
    await prefs.setStringList('sensor_history', history);
  }

  void _loadLastKnownState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = prefs.getString('last_temp') ?? "--";
      _humidity = prefs.getString('last_hum') ?? "--";
    });
  }

  void _sendCommand(String cmd) async {
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng kết nối Bluetooth trước!")),
      );
      return;
    }
    try {
      connection!.output.add(utf8.encode("$cmd\n"));
      await connection!.output.allSent;
    } catch (e) {}
  }

  void _toggleMode() {
    if (!isConnected) return;
    _sendCommand("P");
    setState(() => _isAutoMode = !_isAutoMode);
  }

  void _setFanLevel(int level) {
    if (_isAutoMode || !isConnected) return;
    _sendCommand("M$level");
    setState(() => _fanLevel = level);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TRUNG TÂM ĐIỀU KHIỂN"),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Gọi Widget 
          ControlTab(
            isConnected: isConnected,
            deviceName: _connectedDevice?.name ?? "",
            temperature: _temperature,
            humidity: _humidity,
            isAutoMode: _isAutoMode,
            fanLevel: _fanLevel,
            onToggleMode: _toggleMode,
            onFanLevelChanged: _setFanLevel,
          ),
          
          // TAB 2: Gọi Widget 
          DevicesTab(
            devicesList: _devicesList,
            connectedDevice: _connectedDevice,
            isConnecting: isConnecting,
            onConnect: _connect,
            onDisconnect: _disconnect,
            onRefresh: _getPairedDevices,
          ),

          // TAB 3: Gọi Widget 
          SettingsTab(
            isDarkMode: isDarkMode,
            onThemeChanged: widget.toggleTheme, // Truyền callback lên main
          ),
        ],
      ),
      bottomNavigationBar: SafeArea( // Thanh điều hướng tab
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TabBar( // Thanh điều hướng tab
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
            indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]),
            indicatorPadding: const EdgeInsets.all(5),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Trang chủ"),
              Tab(icon: Icon(Icons.bluetooth_connected_rounded), text: "Thiết bị"),
              Tab(icon: Icon(Icons.settings_rounded), text: "Cài đặt"),
            ],
          ),
        ),
      ),
    );
  }
}