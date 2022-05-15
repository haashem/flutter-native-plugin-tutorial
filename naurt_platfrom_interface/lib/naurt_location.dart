part of 'naurt_platform_interface.dart';

class NaurtLocation {
  final double latitude;
  final double longitude;
  final int timestamp;
  NaurtLocation._({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory NaurtLocation.fromMap(Map<String, dynamic> dataMap) {
    return NaurtLocation._(
      latitude: dataMap['latitude'],
      longitude: dataMap['longitude'],
      timestamp: dataMap['timestamp'],
    );
  }

  @override
  String toString() =>
      'NaurtLocation<lat: $latitude, long: $longitude timestamp: $timestamp>';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NaurtLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
}
