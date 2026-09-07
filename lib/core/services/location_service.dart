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
      throw Exception(
        'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS perangkat.',
      );
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Izin akses lokasi ditolak. Berikan izin lokasi untuk melakukan presensi.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin akses lokasi ditolak permanen. Aktifkan izin lokasi melalui pengaturan aplikasi.',
      );
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && !lastPos.isMocked) {
        position = lastPos;
      } else {
        if (e is Exception) rethrow;
        throw Exception(
          'Gagal mendapatkan sinyal GPS akurat. Pastikan Anda berada di area terbuka.',
        );
      }
    }

    if (position.isMocked) {
      throw Exception(
        'Terdeteksi menggunakan Fake GPS / Lokasi Tiruan. Harap nonaktifkan Fake GPS dan gunakan sinyal GPS asli.',
      );
    }

    return position;
  }

  static double getDistanceInMeters(double lat, double lng) {
    return Geolocator.distanceBetween(lat, lng, ppkdLat, ppkdLng);
  }

  static bool isInsideGeofence(double lat, double lng) {
    return getDistanceInMeters(lat, lng) <= geofenceRadius;
  }
}
