import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../../watersystem/data/services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectDB();
  }

  Future<void> _connectDB() async {
    // Ensure DB is connected eagerly or handled by system provider later
    // For now we just create instance to have logic ready
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        // Connect to DB and save user
        DatabaseService db = DatabaseService();
        await db.connect();
        
        await db.saveUser({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        });
      }
    } catch (e) {
       print("GOOGLE SIGN IN ERROR: $e");
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           title: const Text("Login Failed", style: TextStyle(color: Colors.red)),
           content: Text(e.toString()),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text("OK"),
             ),
           ],
         ),
       );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121B2F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00D2FF), width: 2),
                boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF00D2FF).withOpacity(0.3),
                     blurRadius: 30,
                     spreadRadius: 5,
                   )
                ]
              ),
              child: const Icon(Icons.water_drop, size: 64, color: Color(0xFF00D2FF)),
            ),
            const SizedBox(height: 32),
            const Text(
              "Water System",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Control & Monitor",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 64),
            
            // Google Sign In Button
            _isLoading 
              ? const CircularProgressIndicator(color: Color(0xFF00D2FF))
              : GestureDetector(
                  onTap: _handleGoogleSignIn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Placeholder for Google Logo (simple colored G)
                         ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Colors.blue, Colors.red, Colors.yellow, Colors.green],
                                ).createShader(bounds),
                            child: const Text('G', style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        const SizedBox(width: 12),
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
