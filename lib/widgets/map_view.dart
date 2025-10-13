import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatefulWidget {
  final double userLat;
  final double userLng;
  final List<dynamic> rooms;
  final Map<String, dynamic>? detectedRoom;

  const MapView({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.rooms,
    this.detectedRoom,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.userLat, widget.userLng),
        initialZoom: 18.0,
        maxZoom: 18.0,
        minZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.absensi_ruangan',
        ),
        CircleLayer(
          circles: [
            for (final room in widget.rooms)
              CircleMarker(
                point: LatLng(room['latitude'], room['longitude']),
                color: room['id'] == widget.detectedRoom?['id']
                    ? Colors.green.withAlpha((255 * 0.3).toInt())
                    : Colors.blue.withAlpha((255 * 0.2).toInt()),
                borderColor: room['id'] == widget.detectedRoom?['id']
                    ? Colors.green
                    : Colors.blue,
                borderStrokeWidth: 2,
                radius: 10,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final room in widget.rooms)
              Marker(
                point: LatLng(room['latitude'], room['longitude']),
                width: 80,
                height: 40,
                child: Column(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      color: room['id'] == widget.detectedRoom?['id']
                          ? Colors.green
                          : Colors.blue,
                      size: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        room['name'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.userLat, widget.userLng),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Anda',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}