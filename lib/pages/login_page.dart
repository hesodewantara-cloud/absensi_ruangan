// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login berhasil!')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Absensi Ruangan",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login menggunakan akun Google Anda",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Icon(Icons.login_rounded, color: Colors.white),
                          label: const Text(
                            "Login dengan Google",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
