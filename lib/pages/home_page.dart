import 'dart:async';

import 'package:absensi_ruangan/pages/register_name_page.dart';
import 'package:absensi_ruangan/widgets/map_view.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/image_service.dart';
import 'izin_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentTime = '';
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _currentRoom;
  bool _isLoading = false;
  List<dynamic> _rooms = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _startTimer();
    _checkCurrentLocation();
  }

  void _startTimer() {
    // Update time every second
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final user = supabaseService.client.auth.currentUser;

      if (user != null) {
        final profile = await supabaseService.getUserProfile(user.id);
        setState(() {
          _userProfile = profile;
          if (_userProfile != null) {
            _userProfile!['email'] = user.email;
          }
        });

        // If user doesn't have name, navigate to register name page
        if (profile == null || profile['name'] == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RegisterNamePage()),
          );
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _checkCurrentLocation() async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);

      final position = await locationService.getCurrentLocation();
      final rooms = await supabaseService.getRooms();

      final detectedRoomResult = await locationService.detectRoom(
        position.latitude,
        position.longitude,
        rooms,
      );

      setState(() {
        _currentPosition = position;
        _rooms = rooms;
        _currentRoom = detectedRoomResult != null ? detectedRoomResult['room'] : null;
      });
    } catch (e) {
      print('Error checking location: $e');
    }
  }

  Future<void> _handleAbsen() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);
      final imageService = Provider.of<ImageService>(context, listen: false);
      final user = supabaseService.client.auth.currentUser!;

      // 1. Dapatkan lokasi terkini
      final position = await locationService.getCurrentLocation();

      // 2. Dapatkan daftar ruangan
      final rooms = await supabaseService.getRooms();

      // 3. Deteksi ruangan
      final detectionResult = await locationService.detectRoom(
        position.latitude,
        position.longitude,
        rooms,
      );

      if (detectionResult == null) {
        throw Exception('Anda tidak berada di area ruangan manapun.');
      }

      // 4. Ambil foto selfie
      final XFile? photo = await imageService.takePicture();
      if (photo == null) {
        // User cancelled the camera
        setState(() => _isLoading = false);
        return;
      }

      // 5. Upload foto ke storage
      final fileName = imageService.generateFileName(user.id);
      final photoUrl = await supabaseService.uploadAttendancePhoto(photo.path, fileName);

      // 6. Simpan data absensi
      await supabaseService.submitAttendance({
        'user_id': user.id,
        'room_id': detectionResult['room']['id'],
        'photo_url': photoUrl,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 7. Tampilkan konfirmasi sukses
      _showSuccessDialog(detectionResult['room']['name']);

    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String roomName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
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
            Text('✅ Absensi berhasil disimpan'),
            SizedBox(height: 8),
            Text('Nama: ${_userProfile?['name'] ?? ''}'),
            Text('Ruangan: $roomName'),
            Text('Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Gagal Absen'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
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
          backgroundColor: Color(0xFF2E4B9C),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text(
                    'Absen Sekarang',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AbsensiRuangan'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final supabaseService = Provider.of<SupabaseService>(context, listen: false);
              await supabaseService.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF2E4B9C),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userProfile?['name'] ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _userProfile?['email'] ?? '',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Time and Date
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _currentTime.isEmpty
                          ? 'Loading...'
                          : '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())} • $_currentTime',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E4B9C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Location Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Terdeteksi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _currentRoom?['name'] ?? 'Tidak terdeteksi di ruangan manapun',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _currentRoom != null ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (_currentRoom != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Anda berada dalam area ${_currentRoom!['name']}',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                _buildAbsenButton(),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IzinPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
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

            Spacer(),

            // Mini Map
            Card(
              child: Container(
                height: 150,
                width: double.infinity,
                child: _currentPosition != null
                    ? Stack(
                        children: [
                          MapView(
                            userLat: _currentPosition!.latitude,
                            userLng: _currentPosition!.longitude,
                            rooms: _rooms,
                            detectedRoom: _currentRoom,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: FloatingActionButton.small(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MapPage()),
                                );
                              },
                              child: Icon(Icons.fullscreen),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Memuat peta...'),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}