import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSheetsService {
  // TODO: User will replace this with their deployed Web App URL
  static const String _webAppUrl = "https://script.google.com/macros/s/AKfycbzmI8-XNaz4gVspf7M3_kHDh64og3e1jPvtx5lOrLetZ08-edCzf2wkIzttiZo1q2lQ/exec";

  Future<void> appendRow({
    required String userId,
    required double oxygen,
    required bool fanStatus,
  }) async {
    if (_webAppUrl == "REPLACE_WITH_YOUR_SCRIPT_URL") {
      print("Google Sheets URL not configured.");
      return;
    }

    try {
      final DateTime now = DateTime.now();
      final String date = "${now.year}-${now.month}-${now.day}";
      final String time = "${now.hour}:${now.minute}:${now.second}";

      // Payload: UserID | Date | Time | Oxygen | Fan
      final Map<String, dynamic> data = {
        "userID": userId,
        "date": date,
        "time": time,
        "oxygen": oxygen,
        "fan": fanStatus ? "ON" : "OFF"
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
  Future<List<Map<String, dynamic>>> getLogs(String userId) async {
    if (_webAppUrl == "REPLACE_WITH_YOUR_SCRIPT_URL") return [];

    try {
      // Append query parameter
      final response = await http.get(Uri.parse("$_webAppUrl?action=getLogs&userId=$userId"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        print("Failed to fetch logs: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching logs: $e");
      return [];
    }
  }
}
