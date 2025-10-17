import 'package:geolocator/geolocator.dart';
import '../models/room_model.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif.');
    }

    // Cek izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  RoomModel? detectRoom(
    double userLat,
    double userLng,
    List<RoomModel> rooms,
  ) {
    RoomModel? closestRoom;
    double closestDistance = double.infinity;

    for (final room in rooms) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        room.latitude,
        room.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestRoom = room;
      }
    }

    if (closestRoom != null && closestDistance <= closestRoom.radiusMeters) {
      return closestRoom;
    }

    return null;
  }
}
