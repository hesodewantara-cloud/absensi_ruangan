import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/attendance_model.dart';
import '../models/sick_leave_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- User methods ---
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromMap(response, userId);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserName(String userId, String name) async {
    try {
      await _client
          .from('users')
          .update({'name': name})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user name: $e');
      rethrow;
    }
  }

  // --- Room methods ---
  Future<List<RoomModel>> getRooms() async {
    try {
      final response = await _client.from('rooms').select();
      return (response as List)
          .map((roomMap) => RoomModel.fromMap(roomMap))
          .toList();
    } catch (e) {
      debugPrint('Error getting rooms: $e');
      return [];
    }
  }

  // --- Attendance methods ---
  Future<void> submitAttendance(AttendanceModel attendance) async {
    try {
      await _client.from('attendance').insert(attendance.toMap());
    } catch (e) {
      debugPrint('Error submitting attendance: $e');
      rethrow;
    }
  }

  // --- Sick leave methods ---
  Future<void> submitSickLeave(SickLeaveModel sickLeave) async {
    try {
      await _client.from('sick_leaves').insert(sickLeave.toMap());
    } catch (e) {
      debugPrint('Error submitting sick leave: $e');
      rethrow;
    }
  }

  // --- Storage methods ---
  Future<String> uploadPhoto(String bucket, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      await _client.storage.from(bucket).upload(fileName, file);
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }
}