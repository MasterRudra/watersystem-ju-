import 'package:flutter/material.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  bool isWiFiSelected = false; // BLE default
  bool isConnected = true;

  String deviceName = "ESP32 Controller";
  String ipAddress = "192.168.1.100";

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0B1220);
    const cardColor = Color(0xFF111827);
    const accentBlue = Color(0xFF06B6D4);
    const dangerRed = Color(0xFFB91C1C);
    const mutedText = Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Water System',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                      color: isConnected
                          ? const Color(0xFF22C55E)
                          : dangerRed,
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
                              ? "Data stream active. Monitoring sensors."
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

            // ================= CONNECTION CARD =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Connection Mode",
                      style: TextStyle(color: mutedText, fontSize: 13)),
                  const SizedBox(height: 12),

                  // ---------- WIFI / BLE SWITCH ----------
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _modeButton(
                          label: "WiFi",
                          icon: Icons.wifi,
                          active: isWiFiSelected,
                          color: accentBlue,
                          onTap: () =>
                              setState(() => isWiFiSelected = true),
                        ),
                        _modeButton(
                          label: "BLE",
                          icon: Icons.bluetooth,
                          active: !isWiFiSelected,
                          color: accentBlue,
                          onTap: () =>
                              setState(() => isWiFiSelected = false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- DEVICE NAME ----------
                  _editableField(
                    label: "Device Name",
                    value: deviceName,
                    onSave: (v) => setState(() => deviceName = v),
                  ),

                  const SizedBox(height: 20),

                  // ---------- IP ADDRESS ----------
                  _editableField(
                    label: "IP Address",
                    value: ipAddress,
                    onSave: (v) => setState(() => ipAddress = v),
                  ),

                  const SizedBox(height: 24),

                  // ---------- DISCONNECT ----------
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
                        setState(() => isConnected = false);
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MODE BUTTON =================
  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= EDITABLE FIELD =================
  Widget _editableField({
    required String label,
    required String value,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF121B2F),
                title: Text("Edit $label",
                    style: const TextStyle(color: Colors.white)),
                content: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF1F2A44),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                    const Text("CANCEL", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {
                      onSave(controller.text.trim().isEmpty
                          ? value
                          : controller.text.trim());
                      Navigator.pop(context);
                    },
                    child: const Text("SAVE",
                        style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value,
                style:
                const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
