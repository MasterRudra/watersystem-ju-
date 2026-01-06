import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:watersystem/features/watersystem/presentation/providers/system_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SystemProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _topTitleBar(provider.isConnected),
                const SizedBox(height: 14),
                _header(provider.isConnected),
                const SizedBox(height: 16),
                _pumpGrid(context, provider),
                const SizedBox(height: 16),
                _liveMetricsSection(provider),
                const SizedBox(height: 16),
                _systemControl(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header(bool isOnline) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Dashboard",
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
      Text(
        isOnline ? "ONLINE" : "OFFLINE",
        style: TextStyle(
          color: isOnline ? const Color(0xFF22E58A) : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ---------------- PUMP GRID ----------------
  Widget _pumpGrid(BuildContext context, SystemProvider provider) {
    bool areControlsEnabled = provider.isConnected && !provider.isAutoMode;
    
    return Row(
      children: [
        PumpSwitchCard(
          title: provider.pump1Name,
          isOn: provider.pump1On,
          isEnabled: areControlsEnabled,
          onToggle: () {
            if (areControlsEnabled) provider.togglePump1(!provider.pump1On);
          },
          onLongPress: () => _renamePumpDialog(context, provider, 1),
        ),
        const SizedBox(width: 12),
        PumpSwitchCard(
          title: provider.pump2Name,
          isOn: provider.pump2On,
          isEnabled: areControlsEnabled,
          onToggle: () {
            if (areControlsEnabled) provider.togglePump2(!provider.pump2On);
          },
          onLongPress: () => _renamePumpDialog(context, provider, 2),
        ),
      ],
    );
  }

  // ---------------- DIALOG TO RENAME PUMP ----------------
  void _renamePumpDialog(BuildContext context, SystemProvider provider, int pumpNumber) {
    final TextEditingController controller = TextEditingController(
      text: pumpNumber == 1 ? provider.pump1Name : provider.pump2Name,
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
              provider.updatePumpName(pumpNumber, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // ---------------- LIVE METRICS ----------------
  Widget _liveMetricsSection(SystemProvider provider) => Column(
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
      // TIME FILTER TABS
      _timeFilterSelector(provider),
      const SizedBox(height: 12),
      
      // MERGED CARD
      _combinedOxygenGraph(provider),
      
      const SizedBox(height: 12),
      _metricCard(child: _motorStatusHistory(provider)),
    ],
  );

  Widget _timeFilterSelector(SystemProvider provider) {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: provider.timeFrames.map((frame) {
          bool isSelected = provider.selectedTimeFrame == frame;
          return GestureDetector(
            onTap: () => provider.selectTimeFrame(frame),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1F2A44) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                frame,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00D2FF) : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- COMBINED OXYGEN & GRAPH CARD ----------------
  Widget _combinedOxygenGraph(SystemProvider provider) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: const Color(0xFF121B2F),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF1F2A44)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: Stack(
      children: [
        // 1. BACKGROUND CHART
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 60, right: 0, left: 0, bottom: 0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(color: Colors.white.withOpacity(0.5), strokeWidth: 1, dashArray: [3, 3]),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF00D2FF),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF1F2A44),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            '${barSpot.y.toStringAsFixed(1)} mg/L\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: "Time: 12:00 PM", // Placeholder time
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                ),
                minX: 0,
                maxX: 50,
                minY: 0,
                maxY: 15, // Oxygen range 0-15 typical
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.oxygenHistory.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: const Color(0xFF00D2FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00D2FF).withOpacity(0.3),
                          const Color(0xFF00D2FF).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. FOREGROUND TEXT INFO
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "OXYGEN LEVEL",
                    style: TextStyle(
                      color: Color(0xFF7C8DB5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        provider.oxygenLevel.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          "mg/L",
                          style: TextStyle(
                            color: Color(0xFF00D2FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Status Indicator using Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F253A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.waves, color: Color(0xFF00D2FF)),
              )
            ],
          ),
        ),
      ],
    ),
  );

  // ---------------- MOTOR HISTORY ----------------
  Widget _motorStatusHistory(SystemProvider provider) => SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("MOTOR STATUS", style: TextStyle(color: Colors.amber)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: provider.motorLogs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  provider.motorLogs[i],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );


  // ---------------- SYSTEM CONTROL (EMERGENCY STOP) ----------------
  Widget _systemControl(SystemProvider provider) => GestureDetector(
    onTap: provider.emergencyStop,
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

  Widget _topTitleBar(bool isOnline) => Row(
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOnline ? const Color(0xFF00E5FF) : Colors.grey,
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
  final bool isEnabled;

  const PumpSwitchCard({
    super.key,
    required this.title,
    required this.isOn,
    required this.onToggle,
    required this.onLongPress,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? onToggle : null,
        onLongPress: onLongPress,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
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
                  isEnabled ? (isOn ? "ON" : "OFF") : "LOCKED",
                  style: TextStyle(
                      color: isEnabled 
                        ? (isOn ? const Color(0xFF00E5FF) : Colors.grey)
                        : Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
