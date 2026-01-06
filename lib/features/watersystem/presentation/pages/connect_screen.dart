import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:watersystem/features/watersystem/presentation/providers/system_provider.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  // Discovery
  bool _isDiscovering = false;
  List<BluetoothDiscoveryResult> _scanResults = [];
  List<BluetoothDevice> _bondedDevices = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _getBondedDevices();
  }

  Future<void> _checkPermissions() async {
    // Request all necessary permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }
  
  Future<void> _getBondedDevices() async {
    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      if (mounted) {
        setState(() {
          _bondedDevices = bonded;
        });
      }
    } catch (e) {
      print("Error getting bonded devices: $e");
    }
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _scanResults.clear();
    });

    FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      if (mounted) {
        setState(() {
            // Avoid duplicates
            final existingIndex = _scanResults.indexWhere((element) => element.device.address == r.device.address);
            if (existingIndex >= 0) {
              _scanResults[existingIndex] = r;
            } else {
              _scanResults.add(r);
            }
        });
      }
    }).onDone(() {
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    });
  }
  
  void _openBluetoothSettings() {
    FlutterBluetoothSerial.instance.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0B1220);
    const cardColor = Color(0xFF111827);
    const accentBlue = Color(0xFF06B6D4);
    const dangerRed = Color(0xFFB91C1C);
    const mutedText = Color(0xFF9CA3AF);

    final provider = Provider.of<SystemProvider>(context);
    final isConnected = provider.isConnected;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Water System',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_bluetooth),
            tooltip: "Open System Settings",
            onPressed: _openBluetoothSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= STATUS CARD =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isConnected ? const Color(0xFF22C55E) : dangerRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? "System Online" : "Disconnected",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isConnected
                              ? "Connected to ${provider.connectedDevice?.name ?? 'Device'}"
                              : "No active connection.",
                          style: const TextStyle(
                            color: mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= CONNECTION CONTROLS =================
            if (!isConnected) ...[
              // ------ BONDED DEVICES SECTION ------
              if (_bondedDevices.isNotEmpty) ...[
                 const Text("Paired Devices",
                     style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _bondedDevices.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF1F2A44), height: 1),
                    itemBuilder: (context, index) {
                      final device = _bondedDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.link, color: Colors.amber),
                        title: Text(device.name ?? "Unknown Device", style: const TextStyle(color: Colors.white)),
                        subtitle: Text(device.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                        onTap: () => provider.connectToDevice(device),
                      );
                    },
                  ),
                 ),
                 const SizedBox(height: 24),
              ],
            
              const Text("Available Devices",
                   style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // SCAN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isDiscovering ? null : _startDiscovery,
                  icon: _isDiscovering 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh),
                  label: Text(_isDiscovering ? "Scanning..." : "Scan for Devices"),
                ),
              ),
              
              const SizedBox(height: 10),

              // SCAN RESULTS LIST
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: _scanResults.isEmpty 
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No new devices found", style: TextStyle(color: Colors.grey)),
                      )) 
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _scanResults.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1F2A44), height: 1),
                        itemBuilder: (context, index) {
                          final result = _scanResults[index];
                          final device = result.device;
                          return ListTile(
                            title: Text(device.name ?? "Unknown Device", style: const TextStyle(color: Colors.white)),
                            subtitle: Text(device.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: provider.isConnecting 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.bluetooth_connected, color: accentBlue),
                            onTap: provider.isConnecting ? null : () {
                              provider.connectToDevice(device);
                            },
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 20),
              Center(
                 child: TextButton.icon(
                   icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                   label: const Text("Device not found? Pair it in Settings first.", 
                       style: TextStyle(color: Colors.grey, fontSize: 12)),
                   onPressed: _openBluetoothSettings,
                 ),
              )
              
            ] else ...[
               // DISCONNECT BUTTON
               SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    provider.disconnect();
                  },
                  child: const Text(
                    "DISCONNECT",
                    style: TextStyle(
                      letterSpacing: 1.2,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}
