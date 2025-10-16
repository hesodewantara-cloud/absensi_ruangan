import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      // Tangani error di sini, misalnya dengan logging atau melempar kembali
      throw Exception('Gagal melakukan login dengan Google: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Gagal melakukan logout: $e');
    }
  }

  User? get currentUser {
    return _supabase.auth.currentUser;
  }
}