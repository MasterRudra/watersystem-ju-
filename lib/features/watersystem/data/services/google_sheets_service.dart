import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  // TODO: User will replace this with their deployed Web App URL
  static const String _webAppUrl = "https://script.google.com/macros/s/AKfycbzmI8-XNaz4gVspf7M3_kHDh64og3e1jPvtx5lOrLetZ08-edCzf2wkIzttiZo1q2lQ/exec";

  Future<void> appendRow({
    required String userId,
    required String deviceId,
    required double oxygen,
    required bool fanStatus,
    required String mode,
  }) async {
    if (_webAppUrl == "REPLACE_WITH_YOUR_SCRIPT_URL") {
      print("Google Sheets URL not configured.");
      return;
    }

    try {
      final DateTime now = DateTime.now();
      final String date = "${now.year}-${now.month}-${now.day}";
      final String time = "${now.hour}:${now.minute}:${now.second}";

      // Prepare payload matching the requested columns:
      // UserID | DeviceID | Date | Time | Oxygen | Fan | Mode
      final Map<String, dynamic> data = {
        "userID": userId,
        "deviceID": deviceId,
        "date": date,
        "time": time,
        "oxygen": oxygen,
        "fan": fanStatus ? "ON" : "OFF",
        "mode": mode,
      };

      final response = await http.post(
        Uri.parse(_webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 302 || response.statusCode == 200) {
        print("Data logged to Google Sheet successfully.");
      } else {
        print("Failed to log to Sheet: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error logging to Google Sheet: $e");
    }
  }
}
