import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double ppkdLat = -6.210880;
  static const double ppkdLng = 106.812942;
  static const double geofenceRadius = 300.0;
  static const String ppkdAddress =
      'PPKD Jakarta Pusat, Jl. Karet Pasar Baru Barat V No. 23, Bendungan Hilir, Tanah Abang, Jakarta Pusat';

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Position(
        longitude: ppkdLng,
        latitude: ppkdLat,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return Position(
          longitude: ppkdLng,
          latitude: ppkdLat,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Position(
        longitude: ppkdLng,
        latitude: ppkdLat,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return Position(
        longitude: ppkdLng,
        latitude: ppkdLat,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
    }
  }

  static double getDistanceInMeters(double lat, double lng) {
    return Geolocator.distanceBetween(lat, lng, ppkdLat, ppkdLng);
  }

  static bool isInsideGeofence(double lat, double lng) {
    return getDistanceInMeters(lat, lng) <= geofenceRadius;
  }
}
