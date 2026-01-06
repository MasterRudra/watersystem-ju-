import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothSerialService {
  BluetoothConnection? connection;
  StreamSubscription<Uint8List>? _streamSubscription;
  
  // Stream controller to expose received lines of text (e.g., JSON or CSV)
  final StreamController<String> _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  bool get isConnected => connection != null && connection!.isConnected;

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Start discovery for new devices
  Stream<BluetoothDiscoveryResult> startDiscovery() {
    return FlutterBluetoothSerial.instance.startDiscovery();
  }

  /// Connect to a device by address
  Future<void> connect(String address) async {
    try {
      if (isConnected) {
        await disconnect();
      }

      connection = await BluetoothConnection.toAddress(address);
      
      // Listen to incoming data
      _streamSubscription = connection!.input!.listen(_onDataReceived);
      
      // Cleanup on done/error
      _streamSubscription!.onDone(() {
        disconnect();
      });
      
    } catch (e) {
      print('Error connecting to device: $e');
      rethrow;
    }
  }

  /// Disconnect current connection
  Future<void> disconnect() async {
    await _streamSubscription?.cancel();
    await connection?.close();
    connection = null;
    _streamSubscription = null;
  }

  /// Send string data to device
  Future<void> sendData(String data) async {
    if (isConnected) {
      connection!.output.add(Uint8List.fromList(utf8.encode(data + "\n"))); // Add newline for line-based protocols
      await connection!.output.allSent;
    }
  }

  // Buffer to handle fragmented packets
  String _buffer = "";

  void _onDataReceived(Uint8List data) {
    // Decode incoming bytes to string
    String receivedChunk = utf8.decode(data);
    _buffer += receivedChunk;

    // Split by newline to get complete messages
    // This assumes the microcontroller sends data terminated by \n or \r\n
    if (_buffer.contains('\n')) {
      List<String> lines = _buffer.split('\n');
      
      // Process all complete lines
      // The last part might be incomplete, so keep it in buffer
      for (int i = 0; i < lines.length - 1; i++) {
        String line = lines[i].trim();
        if (line.isNotEmpty) {
          _dataStreamController.add(line);
        }
      }
      
      // Keep the last part (remainder) in buffer
      _buffer = lines.last;
    }
  }
  
  void dispose() {
    _dataStreamController.close();
    disconnect();
  }
}
