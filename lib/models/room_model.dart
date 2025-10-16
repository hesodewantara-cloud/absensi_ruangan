class RoomModel {
  final int id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  RoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? 'Unknown Room',
      description: map['description'],
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (map['radius_meters'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
    };
  }
}