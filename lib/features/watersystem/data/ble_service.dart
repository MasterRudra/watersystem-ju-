import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EspBleService {
  static final FlutterBluePlus _ble = FlutterBluePlus.instance;

  static BluetoothDevice? _device;
  static BluetoothCharacteristic? _txChar;
  static BluetoothCharacteristic? _rxChar;

  /// UUIDs (CHANGE if your ESP32 uses different ones)
  static const String SERVICE_UUID =
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String TX_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8"; // write
  static const String RX_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a9"; // notify

  /// Scan & auto-connect
  static Future<bool> scanAndConnect(String deviceName) async {
    try {
      await _ble.startScan(timeout: const Duration(seconds: 5));

      _ble.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.name == deviceName) {
            _device = r.device;
            await _ble.stopScan();
            await _connect();
            return;
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _connect() async {
    if (_device == null) return;

    await _device!.connect(autoConnect: false);
    final services = await _device!.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == TX_UUID) {
            _txChar = c;
          }
          if (c.uuid.toString() == RX_UUID) {
            _rxChar = c;
            await _rxChar!.setNotifyValue(true);
          }
        }
      }
    }
  }

  /// Receive data
  static Stream<String>? receiveData() {
    if (_rxChar == null) return null;

    return _rxChar!.value.map((data) {
      return utf8.decode(data);
    });
  }

  /// Send command
  static Future<void> _send(String cmd) async {
    if (_txChar != null) {
      await _txChar!.write(utf8.encode(cmd), withoutResponse: true);
    }
  }

  /// Fan controls
  static void fanOn() => _send("1");
  static void fanOff() => _send("0");
  static void fanAuto() => _send("A");



  /// Disconnect
  static Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
  }

  static bool get isConnected => _device != null;
}
