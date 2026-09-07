import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/data/models/user_model.dart';
import 'package:absendulu/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      StorageService.getToken() != null &&
      StorageService.getToken()!.isNotEmpty;

  AuthProvider() {
    _initUser();
  }

  void _initUser() {
    final cached = StorageService.getUserData();
    if (cached != null && cached.isNotEmpty) {
      try {
        _user = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.login(email, password);
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin,
    required dynamic batchId,
    required dynamic trainingId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.register(
        name: name,
        email: email,
        password: password,
        jenisKelamin: jenisKelamin,
        batchId: batchId,
        trainingId: trainingId,
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

  Future<void> fetchProfile() async {
    try {
      _user = await _repository.getProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfile({
    required String name,
    String? email,
    String? jenisKelamin,
    dynamic batchId,
    dynamic trainingId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repository.updateProfile(
        name: name,
        email: email,
        jenisKelamin: jenisKelamin,
        batchId: batchId,
        trainingId: trainingId,
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

  Future<bool> updateProfilePhoto(String base64DataUri) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoUrl = await _repository.updateProfilePhoto(base64DataUri);
      if (photoUrl.isNotEmpty && _user != null) {
        _user = _user!.copyWith(profilePhoto: photoUrl);
        await StorageService.saveUserData(jsonEncode(_user!.toJson()));
      } else {
        await fetchProfile();
      }
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

  Future<bool> requestForgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.forgotPassword(email);
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

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
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

  Future<bool> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.changePassword(
        email: email,
        oldPassword: oldPassword,
        newPassword: newPassword,
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

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }
}
