import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../widgets/map_view.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<Map<String, dynamic>> _locationData;

  Future<Map<String, dynamic>> _loadLocationData() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final supabaseService = Provider.of<SupabaseService>(context, listen: false);

    final position = await locationService.getCurrentLocation();
    final rooms = await supabaseService.getRooms();

    final detectedRoomResult = await locationService.detectRoom(
      position.latitude,
      position.longitude,
      rooms,
    );

    return {
      'position': position,
      'rooms': rooms,
      'detectedRoom': detectedRoomResult != null ? detectedRoomResult['room'] : null,
    };
  }

  @override
  void initState() {
    super.initState();
    _locationData = _loadLocationData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peta Lokasi'),
        backgroundColor: Color(0xFF2E4B9C),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _locationData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _locationData = _loadLocationData();
                      });
                    },
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final position = data['position'] as Position;
          final rooms = data['rooms'] as List<dynamic>;
          final detectedRoom = data['detectedRoom'] as Map<String, dynamic>?;

          return MapView(
            userLat: position.latitude,
            userLng: position.longitude,
            rooms: rooms,
            detectedRoom: detectedRoom,
          );
        },
      ),
    );
  }
}