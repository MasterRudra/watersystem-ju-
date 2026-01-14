import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watersystem/features/watersystem/presentation/pages/connect_screen.dart';
import 'package:watersystem/features/watersystem/presentation/pages/dashboard_screen.dart';
import 'package:watersystem/features/watersystem/presentation/pages/settings_screen.dart';
import 'package:watersystem/features/auth/presentation/pages/login_screen.dart';
import 'package:watersystem/features/auth/data/services/auth_service.dart';

import 'package:provider/provider.dart';
import 'package:watersystem/features/watersystem/presentation/providers/system_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
     await Firebase.initializeApp();
  } catch(e) {
     print("Firebase Init Error: $e");
  }

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B1220),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF))),
          );
        }
        
        if (snapshot.hasData) {
           return const HomeNav();
        }
        
        return const LoginScreen();
      },
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
