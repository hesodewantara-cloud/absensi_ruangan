import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatefulWidget {
  final double userLat;
  final double userLng;
  final List<dynamic> rooms;
  final Map<String, dynamic>? detectedRoom;

  const MapView({
    Key? key,
    required this.userLat,
    required this.userLng,
    required this.rooms,
    this.detectedRoom,
  }) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
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
        center: LatLng(widget.userLat, widget.userLng),
        zoom: 18.0,
        maxZoom: 18.0,
        minZoom: 16.0,
      ),
      children: [
        // Tile Layer - OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.absensi_ruangan',
        ),

        // Circle Layer - Radius ruangan
        CircleLayer(
          circles: [
            for (final room in widget.rooms)
              CircleMarker(
                point: LatLng(room['latitude'], room['longitude']),
                color: room['id'] == widget.detectedRoom?['id']
                    ? Colors.green.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.2),
                borderColor: room['id'] == widget.detectedRoom?['id']
                    ? Colors.green
                    : Colors.blue,
                borderStrokeWidth: 2,
                radius: 10, // 10 meter radius
              ),
          ],
        ),

        // Marker Layer - Ruangan
        MarkerLayer(
          markers: [
            for (final room in widget.rooms)
              Marker(
                point: LatLng(room['latitude'], room['longitude']),
                width: 80,
                height: 40,
                builder: (context) => Column(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      color: room['id'] == widget.detectedRoom?['id']
                          ? Colors.green
                          : Colors.blue,
                      size: 30,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2,2),
                          ),
                        ],
                      ),
                      child: Text(
                        room['name'],
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

        // Marker Layer - User Position
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.userLat, widget.userLng),
              builder: (context) => Column(
                children: [
                  Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 40,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2,2),
                        ),
                      ],
                    ),
                    child: Text(
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