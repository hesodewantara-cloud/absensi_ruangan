import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Auth methods
  Future<AuthResponse> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // User methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }

  Future<void> createUserProfile(Map<String, dynamic> profile) async {
    await client
        .from('users')
        .insert(profile);
  }

  Future<void> updateUserName(String userId, String name) async {
    await client
        .from('users')
        .update({'name': name})
        .eq('id', userId);
  }

  // Room methods
  Future<List<dynamic>> getRooms() async {
    final response = await client
        .from('rooms')
        .select();

    return response;
  }

  // Attendance methods
  Future<void> submitAttendance(Map<String, dynamic> attendance) async {
    await client
        .from('attendance')
        .insert(attendance);
  }

  // Sick leave methods
  Future<void> submitSickLeave(Map<String, dynamic> sickLeave) async {
    await client
        .from('sick_leaves')
        .insert(sickLeave);
  }

  // Storage methods
  Future<String> uploadAttendancePhoto(String filePath, String fileName) async {
    final file = File(filePath);
    await Supabase.instance.client.storage
        .from('attendance_photos')
        .upload(fileName, file);

    final response = Supabase.instance.client.storage
        .from('attendance_photos')
        .getPublicUrl(fileName);

    return response;
  }
}