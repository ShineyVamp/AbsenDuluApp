import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absendulu/core/network/api_exception.dart';
import 'package:absendulu/core/services/location_service.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/data/models/attendance_model.dart';
import 'package:absendulu/data/models/attendance_stats_model.dart';
import 'package:absendulu/data/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();

  Position? _currentPosition;
  double _distanceToPpkd = 0.0;
  bool _isInsideGeofence = false;
  bool _isLoading = false;
  bool _isTodayLoading = true;
  bool _isStatsLoading = true;
  String? _errorMessage;

  AttendanceModel? _todayAttendance;
  AttendanceStatsModel _stats = AttendanceStatsModel();
  List<Map<String, dynamic>> _offlineQueue = [];

  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;

  Position? get currentPosition => _currentPosition;
  double get distanceToPpkd => _distanceToPpkd;
  bool get isInsideGeofence => _isInsideGeofence;
  bool get isLoading => _isLoading;
  bool get isTodayLoading => _isTodayLoading;
  bool get isStatsLoading => _isStatsLoading;
  String? get errorMessage => _errorMessage;
  AttendanceModel? get todayAttendance => _todayAttendance;
  AttendanceStatsModel get stats => _stats;
  DateTime get currentTime => _currentTime;
  List<Map<String, dynamic>> get offlineQueue => _offlineQueue;
  int get pendingOfflineCount => _offlineQueue.length;
  bool get hasPendingOffline => _offlineQueue.isNotEmpty;

  AttendanceProvider() {
    _initTodayCache();
    _startClock();
    initDashboard();
  }

  void _initTodayCache() {
    final todayStr = DateFormatter.formatApiDate(DateTime.now());
    final cachedJson = StorageService.getTodayAttendance(todayStr);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        _todayAttendance = AttendanceModel.fromJson(jsonDecode(cachedJson));
        _isTodayLoading = false;
      } catch (_) {}
    }
  }

  void _loadOfflineQueue() {
    _offlineQueue = StorageService.getOfflineQueue();
    notifyListeners();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  Future<void> initDashboard() async {
    _loadOfflineQueue();
    if (_todayAttendance == null) {
      _isTodayLoading = true;
    }
    _isStatsLoading = true;
    notifyListeners();

    await Future.wait([
      updateLocation(),
      loadTodayAttendance(),
      loadStats(),
    ]);

    if (_offlineQueue.isNotEmpty) {
      syncOfflineAttendance();
    }
  }

  Future<void> updateLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      _currentPosition = pos;
      _distanceToPpkd = LocationService.getDistanceInMeters(
        pos.latitude,
        pos.longitude,
      );
      _isInsideGeofence = LocationService.isInsideGeofence(
        pos.latitude,
        pos.longitude,
      );
      if (!_isInsideGeofence) {
        _errorMessage =
            'Anda berada di luar radius presensi (${_distanceToPpkd.toStringAsFixed(0)} m dari PPKD Jakarta Pusat). Maksimal radius adalah 300 meter.';
      } else {
        _errorMessage = null;
      }
      notifyListeners();
    } catch (e) {
      _currentPosition = null;
      _distanceToPpkd = 0.0;
      _isInsideGeofence = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> clearTodayAttendance() async {
    _todayAttendance = null;
    _isTodayLoading = false;
    final todayStr = DateFormatter.formatApiDate(DateTime.now());
    await StorageService.clearTodayAttendance(todayStr);
    await loadStats();
    notifyListeners();
  }

  Future<void> loadTodayAttendance() async {
    final todayStr = DateFormatter.formatApiDate(DateTime.now());
    if (_todayAttendance == null) {
      final cachedJson = StorageService.getTodayAttendance(todayStr);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          _todayAttendance = AttendanceModel.fromJson(jsonDecode(cachedJson));
          _isTodayLoading = false;
          notifyListeners();
        } catch (_) {}
      }
    }
    try {
      final fetched = await _repository.getTodayAttendance(todayStr);
      if (fetched != null) {
        final existingCheckIn = _todayAttendance?.checkIn;
        final existingCheckInTime = _todayAttendance?.checkInTime;
        final existingCheckOut = _todayAttendance?.checkOut;
        final existingCheckOutTime = _todayAttendance?.checkOutTime;
        _todayAttendance = AttendanceModel(
          id: fetched.id ?? _todayAttendance?.id,
          userId: fetched.userId ?? _todayAttendance?.userId,
          attendanceDate: fetched.attendanceDate ?? todayStr,
          checkIn: fetched.checkIn ?? existingCheckIn,
          checkInTime: fetched.checkInTime ?? existingCheckInTime,
          checkOut: fetched.checkOut ?? existingCheckOut,
          checkOutTime: fetched.checkOutTime ?? existingCheckOutTime,
          checkInLat: fetched.checkInLat ?? _todayAttendance?.checkInLat,
          checkInLng: fetched.checkInLng ?? _todayAttendance?.checkInLng,
          checkOutLat: fetched.checkOutLat ?? _todayAttendance?.checkOutLat,
          checkOutLng: fetched.checkOutLng ?? _todayAttendance?.checkOutLng,
          checkInAddress:
              fetched.checkInAddress ?? _todayAttendance?.checkInAddress,
          checkOutAddress:
              fetched.checkOutAddress ?? _todayAttendance?.checkOutAddress,
          status: fetched.status ?? _todayAttendance?.status,
          alasanIzin: fetched.alasanIzin ?? _todayAttendance?.alasanIzin,
        );
        await StorageService.saveTodayAttendance(
          todayStr,
          jsonEncode(_todayAttendance!.toJson()),
        );
      } else {
        _todayAttendance = null;
        await StorageService.clearTodayAttendance(todayStr);
      }
    } catch (_) {
    } finally {
      _isTodayLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats({DateTime? month}) async {
    final now = month ?? DateTime.now();
    final startStr = DateFormatter.formatApiDate(
      DateTime(now.year, now.month, 1),
    );
    final endStr = DateFormatter.formatApiDate(
      DateTime(now.year, now.month + 1, 0),
    );

    try {
      _stats = await _repository.getAttendanceStats(startStr, endStr);
    } catch (_) {
    } finally {
      _isStatsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkIn() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await updateLocation();
      if (_currentPosition == null || !_isInsideGeofence) {
        _errorMessage = _errorMessage ??
            'Presensi ditolak: Anda berada di luar radius 300m atau GPS tidak aktif.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final pos = _currentPosition!;
      final gpsTimeUtc = pos.timestamp.toUtc();
      final deviceTimeUtc = DateTime.now().toUtc();
      final timeDiff = deviceTimeUtc.difference(gpsTimeUtc).abs();

      if (timeDiff > const Duration(minutes: 2)) {
        _errorMessage =
            'Waktu perangkat tidak sinkron dengan satelit GPS (${timeDiff.inMinutes} menit selisih). Aktifkan waktu otomatis di pengaturan perangkat.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final lastServerTime = StorageService.getLastKnownServerTime();
      if (lastServerTime != null &&
          gpsTimeUtc.isBefore(
            lastServerTime.subtract(const Duration(minutes: 5)),
          )) {
        _errorMessage =
            'Terdeteksi manipulasi waktu (clock rollback). Jam perangkat tidak valid.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final officialTime = pos.timestamp.toLocal();
      final dateStr = DateFormatter.formatApiDate(officialTime);
      final timeStr = DateFormatter.formatApiTime(officialTime);
      final lat = pos.latitude;
      final lng = pos.longitude;

      try {
        final res = await _repository.checkIn(
          date: dateStr,
          time: timeStr,
          lat: lat,
          lng: lng,
          address: LocationService.ppkdAddress,
        );

        _todayAttendance = res;
        await StorageService.saveTodayAttendance(
          dateStr,
          jsonEncode(res.toJson()),
        );
        await loadTodayAttendance();
        if (_todayAttendance == null) {
          _todayAttendance = res;
          await StorageService.saveTodayAttendance(
            dateStr,
            jsonEncode(res.toJson()),
          );
        }
        await loadStats();
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        bool isPureNetworkError = false;
        if (e is ApiException) {
          if (e.isCertificateError) {
            _errorMessage = e.message;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          if (e.isNetworkError) {
            isPureNetworkError = true;
          } else {
            _errorMessage = e.message;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else if (e is SocketException || e is TimeoutException) {
          isPureNetworkError = true;
        }

        if (isPureNetworkError && _isInsideGeofence) {
          final offlineItem = {
            'type': 'check_in',
            'date': dateStr,
            'time': timeStr,
            'lat': lat,
            'lng': lng,
            'address': LocationService.ppkdAddress,
            'gps_timestamp': pos.timestamp.toUtc().toIso8601String(),
            'device_time': DateTime.now().toUtc().toIso8601String(),
          };
          offlineItem['checksum'] = StorageService.generateQueueChecksum(
            offlineItem,
          );
          await StorageService.addOfflineAttendance(offlineItem);
          _offlineQueue = StorageService.getOfflineQueue();
          final localRecord = AttendanceModel(
            attendanceDate: dateStr,
            checkIn: timeStr,
            checkInTime: timeStr,
            checkInLat: lat,
            checkInLng: lng,
            checkInAddress: LocationService.ppkdAddress,
            status: 'masuk',
          );
          _todayAttendance = localRecord;
          await StorageService.saveTodayAttendance(
            dateStr,
            jsonEncode(localRecord.toJson()),
          );
          _errorMessage =
              'Tersimpan offline di antrean lokal. Akan disinkronkan saat online.';
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (outerError) {
      _errorMessage = outerError.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await updateLocation();
      if (_currentPosition == null || !_isInsideGeofence) {
        _errorMessage = _errorMessage ??
            'Presensi ditolak: Anda berada di luar radius 300m atau GPS tidak aktif.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final pos = _currentPosition!;
      final gpsTimeUtc = pos.timestamp.toUtc();
      final deviceTimeUtc = DateTime.now().toUtc();
      final timeDiff = deviceTimeUtc.difference(gpsTimeUtc).abs();

      if (timeDiff > const Duration(minutes: 2)) {
        _errorMessage =
            'Waktu perangkat tidak sinkron dengan satelit GPS (${timeDiff.inMinutes} menit selisih). Aktifkan waktu otomatis di pengaturan perangkat.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final lastServerTime = StorageService.getLastKnownServerTime();
      if (lastServerTime != null &&
          gpsTimeUtc.isBefore(
            lastServerTime.subtract(const Duration(minutes: 5)),
          )) {
        _errorMessage =
            'Terdeteksi manipulasi waktu (clock rollback). Jam perangkat tidak valid.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final officialTime = pos.timestamp.toLocal();
      final dateStr = DateFormatter.formatApiDate(officialTime);
      final timeStr = DateFormatter.formatApiTime(officialTime);
      final lat = pos.latitude;
      final lng = pos.longitude;

      try {
        final res = await _repository.checkOut(
          date: dateStr,
          time: timeStr,
          lat: lat,
          lng: lng,
          address: LocationService.ppkdAddress,
        );

        final existingCheckIn = _todayAttendance?.checkIn;
        final existingCheckInTime = _todayAttendance?.checkInTime;
        final merged = AttendanceModel(
          id: res.id ?? _todayAttendance?.id,
          userId: res.userId ?? _todayAttendance?.userId,
          attendanceDate: res.attendanceDate ?? dateStr,
          checkIn: res.checkIn ?? existingCheckIn,
          checkInTime: res.checkInTime ?? existingCheckInTime,
          checkOut: res.checkOut ?? timeStr,
          checkOutTime: res.checkOutTime ?? timeStr,
          checkInLat: res.checkInLat ?? _todayAttendance?.checkInLat,
          checkInLng: res.checkInLng ?? _todayAttendance?.checkInLng,
          checkOutLat: lat,
          checkOutLng: lng,
          checkInAddress: res.checkInAddress ?? _todayAttendance?.checkInAddress,
          checkOutAddress: LocationService.ppkdAddress,
          status: 'pulang',
          alasanIzin: res.alasanIzin ?? _todayAttendance?.alasanIzin,
        );

        _todayAttendance = merged;
        await StorageService.saveTodayAttendance(
          dateStr,
          jsonEncode(merged.toJson()),
        );
        await loadTodayAttendance();
        if (_todayAttendance == null) {
          _todayAttendance = merged;
          await StorageService.saveTodayAttendance(
            dateStr,
            jsonEncode(merged.toJson()),
          );
        }
        await loadStats();
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        bool isPureNetworkError = false;
        if (e is ApiException) {
          if (e.isCertificateError) {
            _errorMessage = e.message;
            _isLoading = false;
            notifyListeners();
            return false;
          }
          if (e.isNetworkError) {
            isPureNetworkError = true;
          } else {
            _errorMessage = e.message;
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else if (e is SocketException || e is TimeoutException) {
          isPureNetworkError = true;
        }

        if (isPureNetworkError && _isInsideGeofence) {
          final offlineItem = {
            'type': 'check_out',
            'date': dateStr,
            'time': timeStr,
            'lat': lat,
            'lng': lng,
            'address': LocationService.ppkdAddress,
            'gps_timestamp': pos.timestamp.toUtc().toIso8601String(),
            'device_time': DateTime.now().toUtc().toIso8601String(),
          };
          offlineItem['checksum'] = StorageService.generateQueueChecksum(
            offlineItem,
          );
          await StorageService.addOfflineAttendance(offlineItem);
          _offlineQueue = StorageService.getOfflineQueue();
          final existingCheckIn = _todayAttendance?.checkIn;
          final existingCheckInTime = _todayAttendance?.checkInTime;
          final localRecord = AttendanceModel(
            id: _todayAttendance?.id,
            userId: _todayAttendance?.userId,
            attendanceDate: _todayAttendance?.attendanceDate ?? dateStr,
            checkIn: existingCheckIn,
            checkInTime: existingCheckInTime,
            checkOut: timeStr,
            checkOutTime: timeStr,
            checkInLat: _todayAttendance?.checkInLat,
            checkInLng: _todayAttendance?.checkInLng,
            checkOutLat: lat,
            checkOutLng: lng,
            checkInAddress: _todayAttendance?.checkInAddress,
            checkOutAddress: LocationService.ppkdAddress,
            status: 'pulang',
            alasanIzin: _todayAttendance?.alasanIzin,
          );
          _todayAttendance = localRecord;
          await StorageService.saveTodayAttendance(
            dateStr,
            jsonEncode(localRecord.toJson()),
          );
          _errorMessage =
              'Tersimpan offline di antrean lokal. Akan disinkronkan saat online.';
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (outerError) {
      _errorMessage = outerError.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> syncOfflineAttendance() async {
    final queue = StorageService.getOfflineQueue();
    if (queue.isEmpty) return 0;

    int syncedCount = 0;
    final remainingQueue = <Map<String, dynamic>>[];

    for (final item in queue) {
      try {
        final hasChecksum = item.containsKey('checksum');
        if (hasChecksum && !StorageService.verifyQueueChecksum(item)) {
          continue;
        }

        final gpsTimestampStr = item['gps_timestamp'] as String?;
        DateTime? itemGpsTime;
        if (gpsTimestampStr != null && gpsTimestampStr.isNotEmpty) {
          itemGpsTime = DateTime.tryParse(gpsTimestampStr);
        }

        if (itemGpsTime != null) {
          final nowUtc = DateTime.now().toUtc();
          if (itemGpsTime.toUtc().isAfter(
                nowUtc.add(const Duration(minutes: 2)),
              )) {
            continue;
          }
        }

        final type = item['type'] as String?;
        String date =
            item['date'] as String? ??
            DateFormatter.formatApiDate(DateTime.now());
        String time =
            item['time'] as String? ??
            DateFormatter.formatApiTime(DateTime.now());

        if (itemGpsTime != null) {
          final localGps = itemGpsTime.toLocal();
          date = DateFormatter.formatApiDate(localGps);
          time = DateFormatter.formatApiTime(localGps);
        }

        final lat =
            (item['lat'] as num?)?.toDouble() ?? LocationService.ppkdLat;
        final lng =
            (item['lng'] as num?)?.toDouble() ?? LocationService.ppkdLng;
        final address =
            item['address'] as String? ?? LocationService.ppkdAddress;

        if (type == 'check_in') {
          await _repository.checkIn(
            date: date,
            time: time,
            lat: lat,
            lng: lng,
            address: address,
          );
          syncedCount++;
        } else if (type == 'check_out') {
          await _repository.checkOut(
            date: date,
            time: time,
            lat: lat,
            lng: lng,
            address: address,
          );
          syncedCount++;
        }
      } catch (e) {
        if (e is ApiException && !e.isNetworkError) {
        } else {
          remainingQueue.add(item);
        }
      }
    }

    await StorageService.saveOfflineQueue(remainingQueue);
    _offlineQueue = remainingQueue;
    await loadTodayAttendance();
    await loadStats();
    notifyListeners();
    return syncedCount;
  }

  Future<bool> submitIzin(String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = DateFormatter.formatApiDate(now);

      final res = await _repository.submitIzin(date: dateStr, reason: reason);

      _todayAttendance = res;
      await StorageService.saveTodayAttendance(
        dateStr,
        jsonEncode(res.toJson()),
      );
      _isLoading = false;
      await loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}
