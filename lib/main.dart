import 'package:flutter/material.dart';
import 'package:watersystem/features/watersystem/presentation/pages/connect_screen.dart';
import 'package:watersystem/features/watersystem/presentation/pages/dashboard_screen.dart';
import 'package:watersystem/features/watersystem/presentation/pages/settings_screen.dart';

import 'package:provider/provider.dart';
import 'package:watersystem/features/watersystem/presentation/providers/system_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SystemProvider()),
      ],
      child: const WaterSystemApp(),
    ),
  );
}

class WaterSystemApp extends StatelessWidget {
  const WaterSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WaterSystem',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeNav(),
    );
  }
}

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int index = 1;

  final pages = const [
    ConnectScreen(),
    DashboardScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        backgroundColor: const Color(0xFF0B1220),
        selectedItemColor: const Color(0xFF00D2FF),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: "Connect"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
