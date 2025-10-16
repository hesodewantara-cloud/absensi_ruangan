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
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
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
    final locationService = context.read<LocationService>();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update setiap 5 meter
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 18.0);
        _checkIfInRoomRadius(position);
      }
    });
  }

  void _checkIfInRoomRadius(Position position) {
    final locationService = context.read<LocationService>();
    final detectedRoom = locationService.detectRoom(position.latitude, position.longitude, _rooms);

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
                    center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 18.0,
                    maxZoom: 19.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    CircleLayer(
                      circles: _rooms.map((room) {
                        return CircleMarker(
                          point: LatLng(room.latitude, room.longitude),
                          radius: room.radiusMeters.toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.2),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: [
                        // Room markers
                        ..._rooms.map((room) {
                          return Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(room.latitude, room.longitude),
                            builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 30),
                          );
                        }),
                        // User marker
                        if (_currentPosition != null)
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            builder: (ctx) => const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          ),
                      ],
                    ),
                  ],
                ),
    );
  }
}