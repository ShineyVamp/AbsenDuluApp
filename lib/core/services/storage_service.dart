import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyTheme = 'is_dark_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await _prefs?.setString(_keyToken, token);
  }

  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    await _prefs?.remove(_keyToken);
  }

  static Future<void> saveUserData(String jsonString) async {
    await _prefs?.setString(_keyUser, jsonString);
  }

  static String? getUserData() {
    return _prefs?.getString(_keyUser);
  }

  static Future<void> clearUserData() async {
    await _prefs?.remove(_keyUser);
  }

  static Future<void> setIsDarkMode(bool isDark) async {
    await _prefs?.setBool(_keyTheme, isDark);
  }

  static bool getIsDarkMode() {
    return _prefs?.getBool(_keyTheme) ?? false;
  }

  static Future<void> saveTodayAttendance(String date, String jsonString) async {
    await _prefs?.setString('today_attendance_$date', jsonString);
  }

  static String? getTodayAttendance(String date) {
    return _prefs?.getString('today_attendance_$date');
  }

  static Future<void> clearTodayAttendance(String date) async {
    await _prefs?.remove('today_attendance_$date');
  }

  static Future<void> saveHistory(String monthKey, String jsonString) async {
    await _prefs?.setString('history_$monthKey', jsonString);
  }

  static String? getHistory(String monthKey) {
    return _prefs?.getString('history_$monthKey');
  }

  static Future<void> clearAll() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUser);
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('user_meta_') ||
          key.startsWith('today_attendance_') ||
          key.startsWith('history_')) {
        await _prefs?.remove(key);
      }
    }
  }

  static const String _keyOfflineQueue = 'offline_attendance_queue';
  static const String _keyReminderCheckIn = 'reminder_checkin_enabled';
  static const String _keyReminderCheckOut = 'reminder_checkout_enabled';
  static const String _keyReminderCheckInTime = 'reminder_checkin_time';
  static const String _keyReminderCheckOutTime = 'reminder_checkout_time';

  static Future<void> saveUserMeta(String userKey, Map<String, dynamic> meta) async {
    await _prefs?.setString('user_meta_$userKey', jsonEncode(meta));
  }

  static Map<String, dynamic>? getUserMeta(String userKey) {
    final raw = _prefs?.getString('user_meta_$userKey');
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> saveOfflineQueue(List<Map<String, dynamic>> queue) async {
    await _prefs?.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  static List<Map<String, dynamic>> getOfflineQueue() {
    final raw = _prefs?.getString(_keyOfflineQueue);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  static Future<void> addOfflineAttendance(Map<String, dynamic> item) async {
    final queue = getOfflineQueue();
    queue.add(item);
    await saveOfflineQueue(queue);
  }

  static Future<void> clearOfflineQueue() async {
    await _prefs?.remove(_keyOfflineQueue);
  }

  static Future<void> setReminderCheckIn(bool enabled) async {
    await _prefs?.setBool(_keyReminderCheckIn, enabled);
  }

  static bool getReminderCheckIn() {
    return _prefs?.getBool(_keyReminderCheckIn) ?? true;
  }

  static Future<void> setReminderCheckOut(bool enabled) async {
    await _prefs?.setBool(_keyReminderCheckOut, enabled);
  }

  static bool getReminderCheckOut() {
    return _prefs?.getBool(_keyReminderCheckOut) ?? true;
  }

  static Future<void> setReminderCheckInTime(String time) async {
    await _prefs?.setString(_keyReminderCheckInTime, time);
  }

  static String getReminderCheckInTime() {
    return _prefs?.getString(_keyReminderCheckInTime) ?? '07:45';
  }

  static Future<void> setReminderCheckOutTime(String time) async {
    await _prefs?.setString(_keyReminderCheckOutTime, time);
  }

  static String getReminderCheckOutTime() {
    return _prefs?.getString(_keyReminderCheckOutTime) ?? '15:00';
  }
}
