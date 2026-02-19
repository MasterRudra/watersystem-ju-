import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watersystem/features/watersystem/data/services/google_sheets_service.dart';
import 'package:watersystem/features/watersystem/data/services/database_service.dart';

class DataLogsScreen extends StatefulWidget {
  const DataLogsScreen({super.key});

  @override
  State<DataLogsScreen> createState() => _DataLogsScreenState();
}

class _DataLogsScreenState extends State<DataLogsScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final DatabaseService _databaseService = DatabaseService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _isLocal = true; // Default to local for easy verification

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isLocal) {
        final data = await _databaseService.getAllLogs();
        setState(() {
          _logs = data;
          _isLoading = false;
        });
      } else {
        if (_userId == null) {
          setState(() => _isLoading = false);
          return;
        }
        final data = await _sheetsService.getLogs(_userId!);
        setState(() {
          _logs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching logs: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: Text(_isLocal ? "Local Device Logs" : "Cloud Data Logs", style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B1220),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Toggle between Local and Cloud
          IconButton(
            icon: Icon(_isLocal ? Icons.cloud_outlined : Icons.storage_outlined, color: const Color(0xFF00D2FF)),
            tooltip: _isLocal ? "Show Cloud Logs" : "Show Local Logs",
            onPressed: () {
              setState(() {
                _isLocal = !_isLocal;
              });
              _fetchData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF)))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notes_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text(
                        _isLocal ? "No data stored on device yet." : "No records found in cloud.", 
                        style: const TextStyle(color: Colors.white54)
                      ),
                    ],
                  )
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF1F2A44)),
                      dataRowColor: MaterialStateProperty.all(const Color(0xFF0B1220)),
                      columns: const [
                        DataColumn(label: Text("Timestamp", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Oxygen", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("P1", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("P2", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Sync", style: TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold))),
                      ],
                      rows: _logs.map((log) {
                        return DataRow(cells: [
                          DataCell(Text(
                            _isLocal 
                              ? _formatTimestamp(log['timestamp'])
                              : "${log['date']} ${log['time']}", 
                            style: const TextStyle(color: Colors.white, fontSize: 13)
                          )),
                          DataCell(Text(
                            _isLocal ? log['oxygenLevel'].toString() : log['oxygen'].toString(), 
                            style: const TextStyle(color: Colors.white)
                          )),
                          DataCell(Text(
                            _isLocal ? (log['pump1Status'] == 1 ? "ON" : "OFF") : log['fan'] ?? "-", 
                            style: TextStyle(color: _getStatusColor(_isLocal ? log['pump1Status'] == 1 : log['fan'] == "ON"))
                          )),
                          DataCell(Text(
                            _isLocal ? (log['pump2Status'] == 1 ? "ON" : "OFF") : "-", 
                            style: TextStyle(color: _getStatusColor(_isLocal ? log['pump2Status'] == 1 : false))
                          )),
                          DataCell(Icon(
                            _isLocal 
                              ? (log['isSynced'] == 1 ? Icons.check_circle : Icons.sync_problem)
                              : Icons.cloud_done,
                            size: 16,
                            color: _isLocal 
                              ? (log['isSynced'] == 1 ? Colors.green : Colors.orange)
                              : Colors.green,
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return "-";
    try {
      final dt = DateTime.parse(timestamp);
      return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp;
    }
  }

  Color _getStatusColor(bool isOn) {
    return isOn ? Colors.greenAccent : Colors.white70;
  }
}
