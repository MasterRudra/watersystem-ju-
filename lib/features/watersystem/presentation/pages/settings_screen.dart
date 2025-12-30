import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(title: const Text("Settings")),
      body: const Center(
        child: Text("Auto Control Settings",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
