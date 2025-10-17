// lib/pages/home_page.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart'; // Dihapus karena tidak digunakan
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/attendance_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/image_service.dart';
import '../services/auth_service.dart';
import 'izin_page.dart';
import 'register_name_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentTime = '';
  UserModel? _userProfile;
  RoomModel? _currentRoom;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _startTimer();
  }

  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initializePage() async {
    await _loadUserProfile();
    await _checkCurrentLocation();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = context.read<AuthService>();
      final supabaseService = context.read<SupabaseService>();
      final user = authService.currentUser;

      if (user != null) {
        final profile = await supabaseService.getUserProfile(user.id);
        if (!mounted) return;

        if (profile == null || profile.name == null || profile.name!.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RegisterNamePage()),
          );
        } else {
          setState(() {
            _userProfile = profile;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _checkCurrentLocation() async {
    try {
      final locationService = context.read<LocationService>();
      final supabaseService = context.read<SupabaseService>();

      final position = await locationService.getCurrentLocation();
      final rooms = await supabaseService.getRooms();
      final detectedRoom =
          locationService.detectRoom(position.latitude, position.longitude, rooms);

      if (!mounted) return;
      setState(() {
        _currentRoom = detectedRoom;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location: $e');
      }
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _handleAbsen() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final locationService = context.read<LocationService>();
      final supabaseService = context.read<SupabaseService>();
      final imageService = context.read<ImageService>();
      final authService = context.read<AuthService>();
      final user = authService.currentUser!;

      final position = await locationService.getCurrentLocation();
      final rooms = await supabaseService.getRooms();
      final detectedRoom =
          locationService.detectRoom(position.latitude, position.longitude, rooms);

      if (detectedRoom == null) {
        throw Exception('Anda tidak berada di area ruangan manapun yang valid.');
      }

      final XFile? photo = await imageService.takePicture();
      if (photo == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final fileName = imageService.generateFileName(user.id);
      final photoUrl = await supabaseService.uploadPhoto(
          'attendance_photos', photo.path, fileName);

      final attendance = AttendanceModel(
        id: 0, // ID akan dibuat oleh database
        userId: user.id,
        roomId: detectedRoom.id,
        photoUrl: photoUrl,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        status: 'present',
      );

      await supabaseService.submitAttendance(attendance);

      if (!mounted) return;
      _showSuccessDialog(detectedRoom.name);

    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Absensi Berhasil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${_userProfile?.name ?? ''}'),
            Text('Ruangan: $roomName'),
            Text(
                'Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Gagal'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAbsen,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E4B9C),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Absen Sekarang', style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: RefreshIndicator(
        onRefresh: _initializePage,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF2E4B9C),
                        backgroundImage: _userProfile?.avatarUrl != null
                            ? NetworkImage(_userProfile!.avatarUrl!)
                            : null,
                        child: _userProfile?.avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?.name ?? 'Loading...',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userProfile?.email ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Waktu Sekarang',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        _currentTime.isEmpty
                            ? 'Loading...'
                            : '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())} • $_currentTime',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E4B9C)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lokasi Terdeteksi',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        _currentRoom?.name ??
                            'Tidak terdeteksi di ruangan manapun',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentRoom != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  _buildAbsenButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const IzinPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services),
                          SizedBox(width: 8),
                          Text('Izin Sakit'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}