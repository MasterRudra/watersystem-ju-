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

  // Last Logged State (to prevent repetitive entries)
  double? _lastLoggedOxygen;
  bool? _lastLoggedPump1;
  bool? _lastLoggedPump2;
  bool? _lastLoggedAuto;

  SystemProvider() {
    _initDatabase();
    // Listen to incoming data
    _bluetoothService.dataStream.listen(_handleIncomingData);
  }

  Future<void> _initDatabase() async {
    // Non-blocking init
    _databaseService.connect().then((_) => print("SQLite initialized")).catchError((e) => print("DB Init Error: $e"));
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
    _recordStateToDB();
    notifyListeners();
  }

  void selectTimeFrame(String frame) {
    _selectedTimeFrame = frame;
    notifyListeners();
  }

  List<double> _generateMockData(String frame) {
    int points = 50;
    double base = 8.0;
    List<double> mock = [];
    for(int i=0; i<points; i++) {
       double val = 8.0 + 2 * sin(i/10.0);  
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
    _recordStateToDB();
    notifyListeners();
  }

  void togglePump2(bool value) {
    _pump2On = value;
    _sendControlCommand("PUMP2:${value ? 'ON' : 'OFF'}");
    _logMotorStatus("Pump 2", value);
    _recordStateToDB();
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

    bool stateChanged = false;
    bool oxygenUpdated = false;

    try {
      // 1. JSON Format: {"oxygen": 8.5, "pump1": true, "pump2": false}
      if (data.startsWith('{') && data.endsWith('}')) {
        final Map<String, dynamic> json = jsonDecode(data);
        
        if (json.containsKey('oxygen')) {
          _oxygenLevel = (json['oxygen'] as num).toDouble();
          _oxygenHistory.add(_oxygenLevel);
          if (_oxygenHistory.length > 50) _oxygenHistory.removeAt(0);
          oxygenUpdated = true;
          stateChanged = true;
        }

        if (json.containsKey('pump1')) {
          bool newVal = json['pump1'] as bool;
          if (_pump1On != newVal) {
            _pump1On = newVal;
            _logMotorStatus("Pump 1", newVal);
            stateChanged = true;
          }
        }

        if (json.containsKey('pump2')) {
          bool newVal = json['pump2'] as bool;
          if (_pump2On != newVal) {
            _pump2On = newVal;
            _logMotorStatus("Pump 2", newVal);
            stateChanged = true;
          }
        }
      } 
      // 2. Key:Value pair(s) Format: "O:8.5,P1:1" or "Oxygen:8.5"
      else if (data.contains(':')) {
        final tokens = data.split(RegExp(r'[\s,;]+'));
        for (final token in tokens) {
          final parts = token.split(':');
          if (parts.length == 2) {
            final key = parts[0].toLowerCase().trim();
            final value = parts[1].trim();
            
            if (key == 'o' || key == 'oxygen' || key == 'o2' || key == 'val') {
              final double? val = double.tryParse(value);
              if (val != null) {
                _oxygenLevel = val;
                _oxygenHistory.add(val);
                if (_oxygenHistory.length > 50) _oxygenHistory.removeAt(0);
                oxygenUpdated = true;
                stateChanged = true;
              }
            } else if (key == 'p1' || key == 'pump1' || key == 'p') {
              bool newVal = value == '1' || value.toLowerCase() == 'on' || value.toLowerCase() == 'true';
              if (_pump1On != newVal) {
                _pump1On = newVal;
                _logMotorStatus("Pump 1", newVal);
                stateChanged = true;
              }
            } else if (key == 'p2' || key == 'pump2') {
              bool newVal = value == '1' || value.toLowerCase() == 'on' || value.toLowerCase() == 'true';
              if (_pump2On != newVal) {
                _pump2On = newVal;
                _logMotorStatus("Pump 2", newVal);
                stateChanged = true;
              }
            } else if (key == 'a' || key == 'auto') {
              bool newVal = value == '1' || value.toLowerCase() == 'on' || value.toLowerCase() == 'true';
              if (_isAutoMode != newVal) {
                _isAutoMode = newVal;
                stateChanged = true;
              }
            }
          }
        }
      }
      // 3. Raw Number: "8.5"
      else {
        final double? val = double.tryParse(data);
        if (val != null) {
          _oxygenLevel = val;
          _oxygenHistory.add(val);
          if (_oxygenHistory.length > 50) _oxygenHistory.removeAt(0);
          oxygenUpdated = true;
          stateChanged = true;
        }
      }

      if (stateChanged) {
        // Run Auto Control before logging if oxygen was updated
        if (oxygenUpdated && _isAutoMode) {
          _runAutoControlLogic();
        }
        
        // Log final state to SQLite
        _recordStateToDB();
        
        // Final UI update
        notifyListeners();
        
        // Throttled log to Google Sheets if oxygen updated
        if (oxygenUpdated) {
          _logToSheet(_oxygenLevel);
        }
      }
    } catch (e) {
      print("Error parsing data: $e");
    }
  }

  void _runAutoControlLogic() {
    if (_oxygenLevel < 5.0 && !_pump1On) {
      _pump1On = true;
      _sendControlCommand("PUMP1:ON");
      _logMotorStatus("Pump 1", true);
      _motorLogs.insert(0, "AUTO: Low Oxygen ($_oxygenLevel) -> PUMP 1 ON");
    } else if (_oxygenLevel > 6.0 && _pump1On) {
      _pump1On = false;
      _sendControlCommand("PUMP1:OFF");
      _logMotorStatus("Pump 1", false);
      _motorLogs.insert(0, "AUTO: Oxygen Normal ($_oxygenLevel) -> PUMP 1 OFF");
    }
  }

  void _recordStateToDB() {
    // Only save if something changed
    if (_oxygenLevel == _lastLoggedOxygen &&
        _pump1On == _lastLoggedPump1 &&
        _pump2On == _lastLoggedPump2 &&
        _isAutoMode == _lastLoggedAuto) {
      return; 
    }

    _lastLoggedOxygen = _oxygenLevel;
    _lastLoggedPump1 = _pump1On;
    _lastLoggedPump2 = _pump2On;
    _lastLoggedAuto = _isAutoMode;

    final user = FirebaseAuth.instance.currentUser;
    _databaseService.logSensorData({
      'userId': user?.uid ?? 'unknown',
      'oxygen_level': _oxygenLevel,
      'pump1': _pump1On,
      'pump2': _pump2On,
      'isAutoMode': _isAutoMode,
    }).catchError((e) => print("Local Log Error: $e"));
  }

  // Deprecated helper or redirected
  void _updateOxygen(double value, {bool notify = true}) {
    // This is now effectively merged into _handleIncomingData for safety.
    // If called manually (e.g. simulation), we still want it to work.
    _oxygenLevel = value;
    _oxygenHistory.add(value);
    if (_oxygenHistory.length > 50) _oxygenHistory.removeAt(0);
    
    if (_isAutoMode) _runAutoControlLogic();
    _recordStateToDB();
    _logToSheet(value);
    
    if (notify) notifyListeners();
  }

  // Google Sheets Logging
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  DateTime _lastSheetLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isSyncing = false;

  Future<void> _logToSheet(double oxygen) async {
    // Throttle: Log max every 30 seconds
    if (DateTime.now().difference(_lastSheetLogTime).inSeconds < 30) return;
    if (_isSyncing) return;

    _isSyncing = true;
    _lastSheetLogTime = DateTime.now();

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'unknown_user';

    // We can also sync any missed local logs here if we want to implement a robust sync
    // For now, let's just log the current value as before, but safely
    try {
      await _sheetsService.appendRow(
        userId: userId,
        oxygen: oxygen,
        fanStatus: _pump1On || _pump2On, 
      );
      // Optional: Mark local records as synced if we fetch them here
    } catch (e) {
      print("Sheet Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> clearLocalData() async {
    await _databaseService.eraseAllData();
    notifyListeners();
  }
}
