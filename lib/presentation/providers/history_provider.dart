import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/data/models/attendance_model.dart';
import 'package:absendulu/data/repositories/attendance_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final AttendanceRepository _repository = AttendanceRepository();

  List<AttendanceModel> _historyList = [];
  List<AttendanceModel> _currentMonthHistoryList = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentMonth = DateTime.now();

  List<AttendanceModel> get historyList => _historyList;
  List<AttendanceModel> get currentMonthHistoryList =>
      _currentMonthHistoryList.isNotEmpty
          ? _currentMonthHistoryList
          : _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get currentMonth => _currentMonth;

  HistoryProvider() {
    _initHistory();
    refreshCurrentMonth();
    loadHistory(isBackgroundRefresh: _historyList.isNotEmpty);
  }

  String _getMonthKey(DateTime month) {
    return '${month.year}_${month.month}';
  }

  void _initHistory() {
    final now = DateTime.now();
    final currentKey = _getMonthKey(now);
    final currentCached = StorageService.getHistory(currentKey);
    if (currentCached != null && currentCached.isNotEmpty) {
      try {
        final list = jsonDecode(currentCached) as List;
        _currentMonthHistoryList = list
            .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final key = _getMonthKey(_currentMonth);
    final cached = StorageService.getHistory(key);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List;
        _historyList = list
            .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
  }

  Future<void> refreshCurrentMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    final key = _getMonthKey(now);

    try {
      final fresh = await _repository.getHistory(
        startDate: DateFormatter.formatApiDate(start),
        endDate: DateFormatter.formatApiDate(end),
      );
      _currentMonthHistoryList = fresh;
      if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
        _historyList = fresh;
      }
      await StorageService.saveHistory(
        key,
        jsonEncode(fresh.map((e) => e.toJson()).toList()),
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshHistory({DateTime? month}) async {
    if (month != null) {
      _currentMonth = month;
    }
    final key = _getMonthKey(_currentMonth);
    if (_historyList.isEmpty) {
      final cached = StorageService.getHistory(key);
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = jsonDecode(cached) as List;
          _historyList = list
              .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        } catch (_) {}
      }
    }
    await loadHistory(month: month, isBackgroundRefresh: _historyList.isNotEmpty);
  }

  Future<void> loadHistory({DateTime? month, bool isBackgroundRefresh = false}) async {
    if (month != null) {
      _currentMonth = month;
    }
    if (!isBackgroundRefresh && _historyList.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
      final key = _getMonthKey(_currentMonth);

      final fresh = await _repository.getHistory(
        startDate: DateFormatter.formatApiDate(start),
        endDate: DateFormatter.formatApiDate(end),
      );
      _historyList = fresh;
      await StorageService.saveHistory(
        key,
        jsonEncode(fresh.map((e) => e.toJson()).toList()),
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeMonth(DateTime newMonth) {
    _currentMonth = newMonth;
    final key = _getMonthKey(_currentMonth);
    final cached = StorageService.getHistory(key);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List;
        _historyList = list
            .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (_) {
        _historyList = [];
      }
    } else {
      _historyList = [];
    }
    loadHistory(isBackgroundRefresh: _historyList.isNotEmpty);
  }

  Future<bool> deleteAttendance(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteAttendance(id);
      _historyList.removeWhere((item) => item.id == id);
      final key = _getMonthKey(_currentMonth);
      await StorageService.saveHistory(
        key,
        jsonEncode(_historyList.map((e) => e.toJson()).toList()),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
