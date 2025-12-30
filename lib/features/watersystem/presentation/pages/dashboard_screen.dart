import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool pump1On = false;
  bool pump2On = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
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
    );
  }

  Widget _header() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Dashboard",
              style: TextStyle(color: Colors.white, fontSize: 22)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF22E58A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("ONLINE", style: TextStyle(color: Colors.black)),
          ),
        ],
      );

  Widget _pumpGrid() => Row(
        children: [
          _pumpCard("PUMP 1", pump1On, () {
            setState(() => pump1On = !pump1On);
          }),
          const SizedBox(width: 12),
          _pumpCard("PUMP 2", pump2On, () {
            setState(() => pump2On = !pump2On);
          }),
        ],
      );

  Widget _pumpCard(String name, bool online, VoidCallback onToggle) => Expanded(
        child: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 140,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF0F2A44) : const Color(0xFF121B2F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: online
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF1F2A44),
                width: 1.4,
              ),
              boxShadow: online
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Icon(Icons.power,
                    size: 50,
                    color: online
                        ? const Color(0xFF00E5FF)
                        : Colors.grey),
                const SizedBox(height: 6),
                Text(online ? "ON" : "OFF",
                    style: TextStyle(
                        color: online
                            ? const Color(0xFF00E5FF)
                            : Colors.grey)),
              ],
            ),
          ),
        ),
      );

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
            Text("OXYGEN LEVEL",
                style: TextStyle(color: Color(0xFF00D2FF))),
            Text("98.2 %",
                style: TextStyle(
                    color: Color(0xFF00D2FF),
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _voltageFanRow() => Row(
        children: [
          Expanded(child: _smallCard("VOLTAGE", "12.5 V", Colors.amber)),
          const SizedBox(width: 16),
          Expanded(child: _smallCard("FAN STATUS", "OFF", Colors.red)),
        ],
      );

  Widget _smallCard(String title, String value, Color color) => Container(
    height: 100,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF121B2F),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _systemControl() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "SYSTEM CONTROL",
        style: TextStyle(
          color: Color(0xFF7C8DB5),
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),

      GestureDetector(
        onTap: () {
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
      ),
    ],
  );


  Widget _liveMetricsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("LIVE METRICS",
              style: TextStyle(
                  color: Color(0xFF7C8DB5),
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF101A2F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1F2A44))),
            child: Column(
              children: [
                _metricCard(child: _oxygenCard()),
                const SizedBox(height: 12),
                _metricCard(child: _voltageFanRow()),
              ],
            ),
          )
        ],
      );

  Widget _metricCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: const Color(0xFF121B2F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F2A44))),
        child: child,
      );

  Widget _topTitleBar() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: const [
            Icon(Icons.water_drop, color: Color(0xFF3FA9F5), size: 26),
            SizedBox(width: 8),
            Text("জলই জীবন",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700))
          ]),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF00E5FF)),
          ),
        ],
      );
}
