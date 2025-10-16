import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Cek izin lokasi
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

    // ✅ Versi baru dengan parameter locationSettings
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<Map<String, dynamic>?> detectRoom(
    double userLat,
    double userLng,
    List<dynamic> rooms, {
    double maxDistance = 10.0,
  }) async {
    for (final room in rooms) {
      final distance = calculateDistance(
        userLat,
        userLng,
        room['latitude'],
        room['longitude'],
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
