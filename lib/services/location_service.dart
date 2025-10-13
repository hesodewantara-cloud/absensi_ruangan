import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<Map<String, dynamic>?> detectRoom(
    double userLat,
    double userLng,
    List<dynamic> rooms,
    {double maxDistance = 10.0}
  ) async {
    for (final room in rooms) {
      final distance = calculateDistance(
        userLat,
        userLng,
        room['latitude'],
        room['longitude']
      );

      if (distance <= maxDistance) {
        return {
          'room': room,
          'distance': distance,
        };
      }
    }
    return null;
  }
}