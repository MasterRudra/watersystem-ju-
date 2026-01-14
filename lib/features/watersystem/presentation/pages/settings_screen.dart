import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watersystem/features/watersystem/presentation/providers/system_provider.dart';
import 'package:watersystem/features/auth/data/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SystemProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B1220),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader("OPERATION MODE"),
            _buildAutoModeCard(context, provider),
            
            const SizedBox(height: 12),
            _buildTimeSyncCard(context, provider),
            
            const SizedBox(height: 24),
            _sectionHeader("CLOUD INTEGRATION"),
            _buildGoogleSheetsCard(context),
            
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            _sectionHeader("ACCOUNT"),
            _buildLogoutCard(context),
            
            const SizedBox(height: 24),
            _sectionHeader("ABOUT"),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  // ... (previous helper methods)

  Widget _buildLogoutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
        onTap: () async {
          // Confirm dialog
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirm == true) {
            // Sign out directly using the service
            await AuthService().signOut();
            // AuthWrapper will auto-redirect to LoginScreen
          }
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF7C8DB5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAutoModeCard(BuildContext context, SystemProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2A44)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            activeColor: const Color(0xFF00E5FF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: const Text("Auto Control Mode", style: TextStyle(color: Colors.white)),
            subtitle: Text(
              provider.isAutoMode 
                  ? "System controls pumps automatically based on sensor data." 
                  : "Manual control enabled. You have full control.",
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            value: provider.isAutoMode,
            onChanged: (val) {
              if (!provider.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Connect to device first!")),
                );
                return;
              }
              provider.toggleAutoMode(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSyncCard(BuildContext context, SystemProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2A44)),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time_filled, color: Color(0xFF00E5FF)),
        title: const Text("Sync Device Time", style: TextStyle(color: Colors.white)),
        subtitle: const Text("Send phone time to ESP32", style: TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: const Icon(Icons.sync, color: Colors.white54, size: 20),
        onTap: () {
          if (!provider.isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Connect to device first!")),
            );
            return;
          }
           provider.syncDeviceTime();
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Time Sync Command Sent")),
            );
        },
      ),
    );
  }

  Widget _buildGoogleSheetsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2A44)),
      ),
      child: ListTile(
        leading: const Icon(Icons.table_chart, color: Colors.green),
        title: const Text("Connect Google Sheets", style: TextStyle(color: Colors.white)),
        subtitle: const Text("Sync data to cloud automatically", style: TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {
          // Placeholder for Google Sheets integration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google Sheets integration coming soon...")),
          );
        },
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2A44)),
      ),
      child: const Text(
        "Water System Controller v1.0.0\nDeveloped for ESP32 Integration.",
        style: TextStyle(color: Colors.white54, height: 1.5),
      ),
    );
  }
}
