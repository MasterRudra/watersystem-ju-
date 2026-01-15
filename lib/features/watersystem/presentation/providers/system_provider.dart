import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../data/services/bluetooth_serial_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/google_sheets_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SystemProvider extends ChangeNotifier {
  final BluetoothSerialService _bluetoothService = BluetoothSerialService();
  final DatabaseService _databaseService = DatabaseService();

  // Connection State
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _bluetoothService.isConnected;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  // Sensor Data
  double _oxygenLevel = 8.0;
  double get oxygenLevel => _oxygenLevel;
  
  // Graph Data
  final List<double> _oxygenHistory = List.filled(50, 0.0, growable: true);
  String _selectedTimeFrame = '1D';
  final List<String> timeFrames = ['1D', '5D', '1M', '6M', 'YTD'];

  List<double> get oxygenHistory {
    if (_selectedTimeFrame == '1D') return _oxygenHistory;
    return _generateMockData(_selectedTimeFrame);
  }
  
  String get selectedTimeFrame => _selectedTimeFrame;

  // Motor Status
  bool _pump1On = false;
  bool get pump1On => _pump1On;
  
  bool _pump2On = false;
  bool get pump2On => _pump2On;

  String _pump1Name = "PUMP 1";
  String get pump1Name => _pump1Name;
  
  String _pump2Name = "PUMP 2";
  String get pump2Name => _pump2Name;

  // Motor History Log
  final List<String> _motorLogs = [];
  List<String> get motorLogs => _motorLogs;

  // Operation Mode
  bool _isAutoMode = false;
  bool get isAutoMode => _isAutoMode;

  SystemProvider() {
    _initDatabase();
    // Listen to incoming data
    _bluetoothService.dataStream.listen(_handleIncomingData);
    
    // Start a periodic timer to update graph if not connected (Simulation)
    // or just to shift graph for visual effect if needed.
    // actual data update is triggered by _handleIncomingData.
    // REMOVING SIMULATION to strictly follow request: graph only active connected
    // Timer.periodic(const Duration(milliseconds: 500), (timer) {
    //   if (!isConnected) {
    //     // SIMULATION MODE: varying oxygen slightly around 8.0
    //     double fluctuation = (DateTime.now().millisecond % 10) / 10.0 - 0.5;
    //     double newVal = (_oxygenLevel + fluctuation).clamp(0.0, 15.0);
    //     _updateOxygen(newVal); 
    //   }
    // });
  }

  Future<void> _initDatabase() async {
    await _databaseService.connect();
  }

  // ================= CONNECTION METHODS =================

  Future<void> connectToDevice(BluetoothDevice device) async {
    _isConnecting = true;
    notifyListeners();

    try {
      await _bluetoothService.connect(device.address);
      _connectedDevice = device;
      _motorLogs.insert(0, "Connected to ${device.name} - ${_timeString()}");
      notifyListeners();
    } catch (e) {
      print("Connection failed: $e");
      _motorLogs.insert(0, "Connection failed: ${device.name} - ${_timeString()}");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    _connectedDevice = null;
    _motorLogs.insert(0, "Disconnected - ${_timeString()}");
    notifyListeners();
  }

  // ================= CONTROL METHODS =================

  void toggleAutoMode(bool value) {
    _isAutoMode = value;
    _sendControlCommand("AUTO:${value ? 'ON' : 'OFF'}");
    notifyListeners();
  }

  void selectTimeFrame(String frame) {
    _selectedTimeFrame = frame;
    notifyListeners();
  }

  List<double> _generateMockData(String frame) {
    // Generate simplified mock curve for demo
    int points = 50;
    double base = 8.0;
    List<double> mock = [];
    for(int i=0; i<points; i++) {
       // Create a visually pleasing curve
       double val = base + 3 * (i/points) * (i%2==0 ? 1 : -0.5); 
       // Just simple sine wave like variation
       val = 8.0 + 2 * sin(i/10.0);  
       if (frame == '1M') val += 1.0;
       mock.add(val.clamp(0.0, 15.0));
    }
    return mock;
  }

  void updatePumpName(int pumpNumber, String name) {
    if (pumpNumber == 1) _pump1Name = name;
    else _pump2Name = name;
    notifyListeners();
  }

  void togglePump1(bool value) {
    _pump1On = value;
    _sendControlCommand("PUMP1:${value ? 'ON' : 'OFF'}");
    _logMotorStatus("Pump 1", value);
    notifyListeners();
  }

  void togglePump2(bool value) {
    _pump2On = value;
    _sendControlCommand("PUMP2:${value ? 'ON' : 'OFF'}");
    _logMotorStatus("Pump 2", value);
    notifyListeners();
  }

  void emergencyStop() {
    _pump1On = false;
    _pump2On = false;
    _sendControlCommand("EMERGENCY_STOP");
    _motorLogs.insert(0, "EMERGENCY STOP TRIGGERED - ${_timeString()}");
    notifyListeners();
  }

  void _sendControlCommand(String cmd) {
    if (isConnected) {
      _bluetoothService.sendData(cmd);
    } else {
      print("SIMULATION CMD: $cmd");
    }
  }

  void _logMotorStatus(String pump, bool isOn) {
    _motorLogs.insert(0, "$pump ${isOn ? 'ON' : 'OFF'} - ${_timeString()}");
    if (_motorLogs.length > 20) _motorLogs.removeLast();
  }

  String _timeString() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  void syncDeviceTime() {
    final now = DateTime.now();
    // Format: YYYY-MM-DD HH:MM:SS
    String formattedTime = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} "
        "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}";
    
    _sendControlCommand("SYNC_TIME:$formattedTime");
    _motorLogs.insert(0, "Time Sync Command Sent: $formattedTime");
    notifyListeners();
  }

  // ================= DATA HANDLING =================

  void _handleIncomingData(String data) {
    data = data.trim();
    if (data.isEmpty) return;

    // Log raw data for debugging (visible in Motor Logs for now)
    // Log raw data for debugging (visible in Motor Logs for now)
    // _motorLogs.insert(0, "RX: $data");  

    bool shouldNotify = false;

    try {
      // 1. JSON Format: {"oxygen": 8.5, "pump1": true}
      if (data.startsWith('{') && data.endsWith('}')) {
        final Map<String, dynamic> json = jsonDecode(data);
        if (json.containsKey('oxygen')) {
          _updateOxygen((json['oxygen'] as num).toDouble(), notify: false);
          shouldNotify = true;
        }
        if (json.containsKey('pump1')) {
          bool newVal = json['pump1'] as bool;
          if (_pump1On != newVal) {
            _pump1On = newVal;
            _logMotorStatus("Pump 1", newVal);
            shouldNotify = true;
          }
        }
        if (json.containsKey('pump2')) {
          bool newVal = json['pump2'] as bool;
          if (_pump2On != newVal) {
            _pump2On = newVal;
            _logMotorStatus("Pump 2", newVal);
            shouldNotify = true;
          }
        }
      } 
      // 2. Key:Value pair(s) Format: "O:8.5 F:0" or "Oxygen:8.5"
      else if (data.contains(':')) {
        // Split by space to handle multiple pairs like "O:8.5 F:0"
        final tokens = data.split(RegExp(r'\s+'));
        
        for (final token in tokens) {
          final parts = token.split(':');
           if (parts.length == 2) {
            final key = parts[0].toLowerCase().trim();
            final value = parts[1].trim();
            
            if (key == 'o' || key == 'oxygen' || key == 'o2' || key == 'val') {
               final double? val = double.tryParse(value);
               if (val != null) {
                 _updateOxygen(val, notify: false);
                 shouldNotify = true;
               }
            }
          }
        }
      }
      // 3. Raw Number: "8.5"
      else {
        final double? val = double.tryParse(data);
        if (val != null) {
          _updateOxygen(val, notify: false);
          shouldNotify = true;
        }
      }
    } catch (e) {
      print("Error parsing data: $e");
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _updateOxygen(double value, {bool notify = true}) {
    _oxygenLevel = value;
    _oxygenHistory.add(value);
    if (_oxygenHistory.length > 50) {
      _oxygenHistory.removeAt(0);
    }
    
    // Log to MongoDB
    _databaseService.logSensorData({
      'oxygen_level': value,
      'device_id': _connectedDevice?.address ?? 'unknown',
    });

    // Log to Google Sheets (Throttled?)
    _logToSheet(value);

    // AUTO CONTROL LOGIC
    if (_isAutoMode) {
      // Thresholds: ON < 5.0, OFF > 6.0
      if (value < 5.0 && !_pump1On) {
        togglePump1(true);
        _motorLogs.insert(0, "AUTO: Low Oxygen ($value) -> PUMP 1 ON");
      } else if (value > 6.0 && _pump1On) {
        togglePump1(false);
         _motorLogs.insert(0, "AUTO: Oxygen Normal ($value) -> PUMP 1 OFF");
      }
    }

    if (notify) notifyListeners();
  }

  // Google Sheets Logging
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  DateTime _lastSheetLogTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _logToSheet(double oxygen) async {
    // Throttle: Log max every 1 minute to avoid API limits
    if (DateTime.now().difference(_lastSheetLogTime).inMinutes < 1) return;
    
    _lastSheetLogTime = DateTime.now();

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'unknown_user';
    final deviceId = _connectedDevice?.address ?? 'unknown_device';
    final mode = _isAutoMode ? 'AUTO' : 'MANUAL';

    await _sheetsService.appendRow(
      userId: userId,
      oxygen: oxygen,
      fanStatus: _pump1On || _pump2On, 
    );
  }
}
