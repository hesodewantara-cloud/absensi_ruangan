// lib/pages/maps_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  MapsPageState createState() => MapsPageState();
}

class MapsPageState extends State<MapsPage> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  List<RoomModel> _rooms = [];
  Position? _currentPosition;
  bool _isLoading = true;
  String? _lastNotifiedRoomId;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final supabaseService = context.read<SupabaseService>();
      final locationService = context.read<LocationService>();

      final rooms = await supabaseService.getRooms();
      final position = await locationService.getCurrentLocation();

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _currentPosition = position;
          _isLoading = false;
        });
        _startLocationStream();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data peta: ${e.toString()}')),
        );
      }
    }
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update setiap 5 meter
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );

        _checkIfInRoomRadius(position);
      }
    });
  }

  void _checkIfInRoomRadius(Position position) {
    final locationService = context.read<LocationService>();
    final detectedRoom = locationService.detectRoom(
      position.latitude,
      position.longitude,
      _rooms,
    );

    if (detectedRoom != null) {
      if (_lastNotifiedRoomId != detectedRoom.id.toString()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda memasuki area ${detectedRoom.name}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _lastNotifiedRoomId = detectedRoom.id.toString();
        });
      }
    } else {
      // Reset notifikasi jika keluar dari semua area
      if (_lastNotifiedRoomId != null) {
        setState(() {
          _lastNotifiedRoomId = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackPosition = LatLng(-6.175392, 106.827153); // Monas/Jakarta

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Ruangan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(child: Text('Gagal mendapatkan lokasi.'))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentPosition?.latitude ?? fallbackPosition.latitude,
                      _currentPosition?.longitude ?? fallbackPosition.longitude,
                    ),
                    initialZoom: 18.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    // ✅ Gunakan OpenStreetMap tanpa API Key
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.absensi_ruangan',
                    ),
                    // ✅ Gambar lingkaran radius tiap ruangan
                    CircleLayer(
                      circles: _rooms.map((room) {
                        return CircleMarker(
                          point: LatLng(room.latitude, room.longitude),
                          radius: room.radiusMeters.toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.blue.withAlpha(50),
                          borderColor: Colors.blueAccent,
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    // ✅ Marker ruangan dan posisi user
                    MarkerLayer(
                      markers: [
                        // Marker tiap ruangan
                        ..._rooms.map((room) {
                          return Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(room.latitude, room.longitude),
                            child: Tooltip(
                              message: room.name,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          );
                        }),
                        // Marker user
                        if (_currentPosition != null)
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
