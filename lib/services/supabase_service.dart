import 'dart:io';
import 'package:flutter/foundation.dart'; // Import untuk debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // PENYEMPURNAAN: Tambahkan getter untuk stream status autentikasi.
  // Ini cara terbaik untuk mendengarkan perubahan login/logout di seluruh aplikasi.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  // PENYEMPURNAAN: Tambahkan getter untuk user saat ini agar lebih mudah diakses.
  User? get currentUser => client.auth.currentUser;

  // --- Auth methods ---
  Future<void> signInWithGoogle() async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        // PERBAIKAN UTAMA: Hapus garis miring (/) di akhir.
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      // PENYEMPURNAAN: Tambahkan penanganan error.
      debugPrint('Error during Google sign-in: $e');
      rethrow; // Lempar kembali error agar bisa ditangani di UI.
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error during sign-out: $e');
      rethrow;
    }
  }

  // --- User methods ---
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null; // Kembalikan null jika terjadi error.
    }
  }

  Future<void> createUserProfile(Map<String, dynamic> profile) async {
    try {
      await client.from('users').insert(profile);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserName(String userId, String name) async {
    try {
      await client
          .from('users')
          .update({'name': name})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user name: $e');
      rethrow;
    }
  }

  // --- Room methods ---
  Future<List<dynamic>> getRooms() async {
    try {
      final response = await client.from('rooms').select();
      return response;
    } catch (e) {
      debugPrint('Error getting rooms: $e');
      return []; // Kembalikan list kosong jika error.
    }
  }

  // --- Attendance methods ---
  Future<void> submitAttendance(Map<String, dynamic> attendance) async {
    try {
      await client.from('attendance').insert(attendance);
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      rethrow;
    }
  }

  // --- Sick leave methods ---
  Future<void> submitSickLeave(Map<String, dynamic> sickLeave) async {
    try {
      await client.from('sick_leaves').insert(sickLeave);
    } catch (e) {
      debugPrint('Error submitting sick leave: $e');
      rethrow;
    }
  }

  // --- Storage methods ---
  Future<String> uploadPhoto(String bucket, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      await client.storage.from(bucket).upload(fileName, file);

      final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }
}