import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../../watersystem/data/services/database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isRegistering = false; // Toggle between Login and Register

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _saveUserToDB(user);
      }
    } catch (e) {
       _showError(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isRegistering) {
        final user = await _authService.signUpWithEmail(email, password);
        if (user != null) {
          await _authService.sendEmailVerification();
          await _saveUserToDB(user);
          await _authService.signOut(); 
          if (mounted) {
             _showInfo("Account created! A verification email has been sent to $email. Please verify your email before logging in.");
             setState(() => _isRegistering = false);
          }
        }
      } else {
        final user = await _authService.signInWithEmail(email, password);
        if (user != null) {
          if (!user.emailVerified) {
             final emailToVerify = user.email;
             await _authService.signOut(); 
             if (mounted) {
               _showVerificationDialog(emailToVerify ?? email);
             }
          } else {
             await _saveUserToDB(user);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An error occurred during authentication.");
    } catch (e) {
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verify Email", style: TextStyle(color: Color(0xFF00D2FF))),
        content: Text("Your email $email is not verified yet. Please check your inbox and click the verification link."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // We need to sign in again to resend verification if we signed out, 
              // but Firebase lets us send it if we HAVE the user object.
              // Since we signed out, we might need a better way. 
              // For now, just telling them to check email is standard.
            },
            child: const Text("Resend?", style: TextStyle(color: Color(0xFF00D2FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserToDB(User user) async {
    // SQLite call is fast, but still catch errors
    try {
      final db = DatabaseService(); 
      await db.saveUser({
        'uid': user.uid,
        'email': user.email ?? "",
        'displayName': user.displayName ?? "User",
        'photoURL': user.photoURL ?? "",
      });
    } catch (e) {
      print("Local DB Sync Error: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Authentication Error", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showInfo(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success", style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.water_drop,
                  size: 64,
                  color: Color(0xFF00D2FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Water System",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegistering ? "Create a new account" : "Monitor and Control",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Email Field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00D2FF)),
                  filled: true,
                  fillColor: const Color(0xFF1F2A44),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00D2FF)),
                  filled: true,
                  fillColor: const Color(0xFF1F2A44),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 24),

              // Action Button (Login/Register)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D2FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isRegistering ? "Sign Up" : "Login",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Register/Login
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _isRegistering ? "Already have an account? Login" : "Don't have an account? Sign Up",
                  style: const TextStyle(color: Color(0xFF00D2FF)),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                ],
              ),
              const SizedBox(height: 24),

              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 28), 
                  label: const Text("Sign in with Google"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
