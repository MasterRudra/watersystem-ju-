import 'dart:convert';
import 'package:http/http.dart' as http;

class EspWifiService {
  /// Connect check using mDNS name (esp32.local)
  static Future<bool> connect(String deviceName) async {
    try {
      final res = await http
          .get(Uri.parse("http://$deviceName/status"))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get dashboard data
  static Future<Map<String, dynamic>> getStatus(String deviceName) async {
    final res = await http
        .get(Uri.parse("http://$deviceName/status"))
        .timeout(const Duration(seconds: 5));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("ESP32 not responding");
  }

  /// Fan controls
  static Future<void> fanOn(String deviceName) async {
    await http.get(Uri.parse("http://$deviceName/fan/on"));
  }

  static Future<void> fanOff(String deviceName) async {
    await http.get(Uri.parse("http://$deviceName/fan/off"));
  }

  static Future<void> fanAuto(String deviceName) async {
    await http.get(Uri.parse("http://$deviceName/fan/auto"));
  }
}