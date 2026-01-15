import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watersystem/features/watersystem/data/services/google_sheets_service.dart';

class DataLogsScreen extends StatefulWidget {
  const DataLogsScreen({super.key});

  @override
  State<DataLogsScreen> createState() => _DataLogsScreenState();
}

class _DataLogsScreenState extends State<DataLogsScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    final data = await _sheetsService.getLogs(_userId!); // We use UID or Email depending on what we saved. 
    // In our case we saved specific UserID. Let's make sure Apps Script handles filtering.
    
    setState(() {
      _logs = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text("My Data Logs", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B1220),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF)))
          : _logs.isEmpty
              ? const Center(child: Text("No records found.", style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF1F2A44)),
                      dataRowColor: MaterialStateProperty.all(const Color(0xFF0B1220)),
                      columns: const [
                        DataColumn(label: Text("Date", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Time", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Oxygen", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Fan", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Mode", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                      ],
                      rows: _logs.map((log) {
                        return DataRow(cells: [
                          DataCell(Text(log['date']?.toString() ?? "-", style: const TextStyle(color: Colors.white))),
                          DataCell(Text(log['time']?.toString() ?? "-", style: const TextStyle(color: Colors.white))),
                          DataCell(Text(log['oxygen']?.toString() ?? "-", style: const TextStyle(color: Colors.white))),
                          DataCell(Text(log['fan']?.toString() ?? "-", style: const TextStyle(color: Colors.white))),
                          DataCell(Text(log['mode']?.toString() ?? "-", style: const TextStyle(color: Colors.white))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
