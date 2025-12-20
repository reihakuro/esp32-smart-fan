import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// --- QUẢN LÝ TRẠNG THÁI THEME (Global) ---
// Sử dụng ValueNotifier để thông báo thay đổi giao diện toàn app
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
          theme: AppTheme.lightTheme, // Giao diện Sáng (Cam - Be)
          darkTheme: AppTheme.darkTheme, // Giao diện Tối (Xám ấm - Cam)
          home: const SmartFanApp(),
        );
      },
    );
  }
}

// --- CẤU HÌNH BẢNG MÀU (THEME DATA) ---
class AppTheme {
  // Màu chủ đạo (dùng chung)
  static const Color primary = Color(0xFFEA580C);    // Cam đậm
  static const Color secondary = Color(0xFFFDBA74);  // Cam vừa
  static const Color success = Color(0xFF16A34A);    // Xanh lá
  static const Color error = Color(0xFFDC2626);      // Đỏ

  // 1. Cấu hình Light Theme (Cam - Be - Nâu)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF7ED), // Nền Be/Kem
    primaryColor: primary,
    cardColor: const Color(0xFFFFFFFF), // Card Trắng
    dividerColor: secondary.withOpacity(0.3),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFFFFF7ED),
      onSurface: Color(0xFF431407), // Chữ Nâu đậm
    ),
    textTheme: GoogleFonts.nunitoTextTheme().apply(
      bodyColor: const Color(0xFF431407),
      displayColor: const Color(0xFF431407),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFFF7ED),
      foregroundColor: const Color(0xFF431407),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        color: const Color(0xFF431407),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF431407)),
    ),
  );

  // 2. Cấu hình Dark Theme (Xám ấm - Cam)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1C1917), // Nền Xám đen ấm (Stone 900)
    primaryColor: primary,
    cardColor: const Color(0xFF292524), // Card Xám (Stone 800)
    dividerColor: Colors.grey.withOpacity(0.2),
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: Color(0xFF1C1917),
      onSurface: Color(0xFFE7E5E4), // Chữ Trắng ngà (Stone 200)
    ),
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFE7E5E4),
      displayColor: const Color(0xFFE7E5E4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1C1917),
      foregroundColor: const Color(0xFFE7E5E4),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        color: const Color(0xFFE7E5E4),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFE7E5E4)),
    ),
  );
}

class SmartFanApp extends StatefulWidget {
  const SmartFanApp({Key? key}) : super(key: key);

  @override
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
    super.initState();
    // Tăng length lên 3 cho tab Cài đặt
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

  // Hàm chuyển đổi theme Sáng/Tối
  void _toggleTheme(bool isDark) async {
    _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  // --- GIAO DIỆN CHÍNH ---

  @override
  Widget build(BuildContext context) {
    // Lấy theme hiện tại từ context để dùng màu động
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("TRUNG TÂM ĐIỀU KHIỂN"), 
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildControlPage(theme),
          _buildBluetoothPage(theme),
          _buildSettingsPage(theme, isDarkMode), // Tab mới
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70, 
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          decoration: BoxDecoration(
            color: theme.cardColor, // Đổi màu động
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5), // Đổi màu động
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
            
            indicator: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4)
                )
              ]
            ),
            indicatorPadding: const EdgeInsets.all(5),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Trang chủ"),
              Tab(icon: Icon(Icons.bluetooth_connected_rounded), text: "Thiết bị"),
              Tab(icon: Icon(Icons.settings_rounded), text: "Cài đặt"), // Tab 3
            ],
          ),
        ),
      ),
    );
  }

  // TAB 1: BẢNG ĐIỀU KHIỂN
  Widget _buildControlPage(ThemeData theme) {
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
                Text(isConnected 
                  ? "Đã kết nối: ${_connectedDevice?.name}" 
                  : "Chưa kết nối", 
                  style: TextStyle(
                    color: isConnected ? AppTheme.success : AppTheme.error, 
                    fontWeight: FontWeight.w800,
                    fontSize: 13
                  )
                ),
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
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSensorValue(Icons.thermostat_rounded, AppTheme.primary, _temperature, "°C", "Nhiệt độ", theme),
                Container(width: 1.5, height: 60, color: theme.dividerColor),
                _buildSensorValue(Icons.water_drop_rounded, Colors.blueAccent, _humidity, "%", "Độ ẩm", theme),
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
                            letterSpacing: 1.2
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(_isAutoMode ? 'Tự động' : 'Thủ công', 
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w900,
                              color: _isAutoMode ? AppTheme.primary : theme.colorScheme.onSurface
                            )),
                      ],
                    ),
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _isAutoMode,
                        onChanged: isConnected ? (val) => _toggleMode() : null,
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
                     Text("TỐC ĐỘ QUẠT", style: GoogleFonts.nunito(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    bool isSelected = (_fanLevel == index);
                    bool isDisabled = _isAutoMode || !isConnected; 
                    
                    return GestureDetector(
                      onTap: isDisabled ? null : () => _setFanLevel(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppTheme.primary 
                            : (isDisabled ? theme.scaffoldBackgroundColor : AppTheme.secondary.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.transparent,
                            width: 2
                          ),
                          boxShadow: isSelected && !isDisabled ? [
                             BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                          ] : []
                        ),
                        alignment: Alignment.center,
                        child: Text("$index", 
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.w800,
                            color: isSelected 
                              ? Colors.white 
                              : (isDisabled ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.onSurface)
                          )
                        ),
                      ),
                    );
                  }),
                ),
                if (!isConnected)
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                      "* Vui lòng kết nối Bluetooth để điều khiển",
                      style: GoogleFonts.nunito(color: AppTheme.error.withOpacity(0.7), fontSize: 12, fontStyle: FontStyle.italic),
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

  // TAB 2: DANH SÁCH THIẾT BỊ
  Widget _buildBluetoothPage(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("Thiết bị khả dụng", 
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                onPressed: _getPairedDevices,
                style: IconButton.styleFrom(backgroundColor: AppTheme.secondary.withOpacity(0.2)),
              )
            ],
          ),
        ),
        Expanded(
          child: _devicesList.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_searching_rounded, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text("Không tìm thấy thiết bị nào", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: FlutterBluetoothSerial.instance.openSettings, 
                    child: const Text("Mở cài đặt Bluetooth", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))
                  )
                ],
              )
            ) 
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                bool isDevConnected = (connection?.isConnected ?? false) && 
                                      (_connectedDevice?.address == device.address);
                
                return Container(
                  decoration: BoxDecoration(
                    color: isDevConnected ? AppTheme.primary.withOpacity(0.1) : theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDevConnected ? AppTheme.primary : Colors.transparent
                    ),
                    boxShadow: [
                      if(!isDevConnected)
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDevConnected ? AppTheme.primary : theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth_rounded, 
                        color: isDevConnected ? Colors.white : AppTheme.secondary
                      ),
                    ),
                    title: Text(device.name ?? "Không tên", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    subtitle: Text(device.address, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
                    trailing: isDevConnected 
                      ? TextButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text("Ngắt kết nối"),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                          onPressed: _disconnect,
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                          ),
                          onPressed: isConnecting ? null : () => _connect(device),
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

  // TAB 3: CÀI ĐẶT (CUSTOMIZE)
  Widget _buildSettingsPage(ThemeData theme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tuỳ chỉnh giao diện", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ]
            ),
            child: Column(
              children: [
                // Switch Dark Mode
                SwitchListTile(
                  title: const Text("Chế độ Tối", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Giao diện nền tối bảo vệ mắt", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.indigoAccent),
                  ),
                  value: isDarkMode,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    _toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text("Thông tin ứng dụng", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ]
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.green),
              ),
              title: const Text("Phiên bản", style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Text("0.3.8", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValue(IconData icon, Color iconColor, String value, String unit, String label, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
              TextSpan(text: unit, style: GoogleFonts.nunito(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold)),
            ]
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}