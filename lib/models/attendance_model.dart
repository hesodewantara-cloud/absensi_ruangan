class AttendanceModel {
  final int id;
  final String userId;
  final int roomId;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? '',
      roomId: map['room_id'] ?? 0,
      photoUrl: map['photo_url'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      status: map['status'] ?? 'present',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}