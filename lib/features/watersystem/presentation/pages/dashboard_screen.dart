import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool pump1On = false;
  bool pump2On = false;

  String pump1Name = "PUMP 1";
  String pump2Name = "PUMP 2";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _topTitleBar(),
                const SizedBox(height: 14),
                _header(),
                const SizedBox(height: 16),
                _pumpGrid(),
                const SizedBox(height: 16),
                _liveMetricsSection(),
                const SizedBox(height: 16),
                _systemControl(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: const [
      Text(
        "Dashboard",
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
      Text(
        "ONLINE",
        style: TextStyle(
          color: Color(0xFF22E58A),
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ---------------- PUMP GRID ----------------
  Widget _pumpGrid() => Row(
    children: [
      PumpSwitchCard(
        title: pump1Name,
        isOn: pump1On,
        onToggle: () => setState(() => pump1On = !pump1On),
        onLongPress: () => _renamePumpDialog(1),
      ),
      const SizedBox(width: 12),
      PumpSwitchCard(
        title: pump2Name,
        isOn: pump2On,
        onToggle: () => setState(() => pump2On = !pump2On),
        onLongPress: () => _renamePumpDialog(2),
      ),
    ],
  );

  // ---------------- DIALOG TO RENAME PUMP ----------------
  void _renamePumpDialog(int pumpNumber) {
    final TextEditingController controller = TextEditingController(
      text: pumpNumber == 1 ? pump1Name : pump2Name,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121B2F),
        title: const Text(
          "Rename Pump",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Pump Name",
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Color(0xFF1F2A44),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (pumpNumber == 1) {
                  pump1Name = controller.text.isEmpty ? "PUMP 1" : controller.text;
                } else {
                  pump2Name = controller.text.isEmpty ? "PUMP 2" : controller.text;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ---------------- LIVE METRICS ----------------
  Widget _liveMetricsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "LIVE METRICS",
        style: TextStyle(
          color: Color(0xFF7C8DB5),
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101A2F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F2A44)),
        ),
        child: Column(
          children: [
            _metricCard(child: _oxygenCard()),
            const SizedBox(height: 12),
            _metricCard(child: _motorStatusHistory()),
          ],
        ),
      )
    ],
  );

  // ---------------- OXYGEN CARD ----------------
  Widget _oxygenCard() => Container(
    height: 90,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF121B2F),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "OXYGEN LEVEL",
          style: TextStyle(color: Color(0xFF00D2FF)),
        ),
        Text(
          "8.4 mg/L",
          style: TextStyle(
            color: Color(0xFF00D2FF),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  // ---------------- MOTOR HISTORY ----------------
  Widget _motorStatusHistory() {
    final logs = [
      "ON - 00:00:00",
      "ON - 00:00:00",
      "ON - 00:00:00",
      "ON - 00:00:00",
      "ON - 00:00:00",
    ];

    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MOTOR STATUS", style: TextStyle(color: Colors.amber)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  logs[i],
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SYSTEM CONTROL (EMERGENCY STOP) ----------------
  Widget _systemControl() => GestureDetector(
    onTap: () {
      // Turn off both pumps immediately
      setState(() {
        pump1On = false;
        pump2On = false;
      });
    },
    child: Container(
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(.4), blurRadius: 18),
        ],
      ),
      child: const Text(
        "Emergency Stop All",
        style: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _metricCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF121B2F),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF1F2A44)),
    ),
    child: child,
  );

  Widget _topTitleBar() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: const [
          Icon(Icons.water_drop,
              color: Color(0xFF3FA9F5), size: 26),
          SizedBox(width: 8),
          Text(
            "Water System",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
      Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF00E5FF),
        ),
      ),
    ],
  );
}

// ===================================================================
// CUSTOM PUMP SWITCH CARD
// ===================================================================
class PumpSwitchCard extends StatelessWidget {
  final String title;
  final bool isOn;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const PumpSwitchCard({
    super.key,
    required this.title,
    required this.isOn,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onToggle,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 140,
          decoration: BoxDecoration(
            color: isOn ? const Color(0xFF0F2A44) : const Color(0xFF121B2F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOn ? const Color(0xFF00E5FF) : const Color(0xFF1F2A44),
              width: 1.4,
            ),
            boxShadow: isOn
                ? [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(.35),
                blurRadius: 18,
              )
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Icon(Icons.power,
                  size: 50,
                  color: isOn ? const Color(0xFF00E5FF) : Colors.grey),
              const SizedBox(height: 6),
              Text(
                isOn ? "ON" : "OFF",
                style: TextStyle(
                    color: isOn ? const Color(0xFF00E5FF) : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
