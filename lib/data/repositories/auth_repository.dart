import 'dart:convert';
import 'package:absendulu/core/constants/api_endpoints.dart';
import 'package:absendulu/core/network/api_client.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/data/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      withAuth: false,
      body: {'email': email, 'password': password},
    );

    if (response is Map<String, dynamic> && response.containsKey('data')) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final token = data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await StorageService.saveToken(token);
        }
        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await StorageService.saveUserData(jsonEncode(user.toJson()));
          return user;
        }
      }
    }

    throw Exception('Format data respon login tidak sesuai');
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String jenisKelamin,
    required dynamic batchId,
    required dynamic trainingId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      withAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'jenis_kelamin': jenisKelamin,
        'batch_id': batchId,
        'training_id': trainingId,
        'profile_photo': '',
      },
    );

    if (response is Map<String, dynamic> && response.containsKey('data')) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final token = data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          await StorageService.saveToken(token);
        }
        if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await StorageService.saveUserData(jsonEncode(user.toJson()));
          return user;
        }
      }
    }

    throw Exception('Format data respon registrasi tidak sesuai');
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    if (response is Map<String, dynamic>) {
      final data = response.containsKey('data') ? response['data'] : response;
      if (data is Map<String, dynamic>) {
        final userMap =
            (data.containsKey('user') && data['user'] is Map<String, dynamic>)
                ? data['user'] as Map<String, dynamic>
                : data;
        final existingRaw = StorageService.getUserData();
        UserModel? existingUser;
        if (existingRaw != null && existingRaw.isNotEmpty) {
          try {
            existingUser = UserModel.fromJson(jsonDecode(existingRaw));
          } catch (_) {}
        }
        var user = UserModel.fromJson(userMap);
        if (user.profilePhoto == null || user.profilePhoto!.isEmpty) {
          user = user.copyWith(profilePhoto: existingUser?.profilePhoto);
        }
        if (user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty) {
          user = user.copyWith(profilePhotoUrl: existingUser?.profilePhotoUrl);
        }
        if (user.createdAt == null || user.createdAt!.isEmpty) {
          user = user.copyWith(createdAt: existingUser?.createdAt);
        }
        if (user.batchId == null && existingUser?.batchId != null) {
          user = user.copyWith(batchId: existingUser?.batchId);
        }
        if (user.trainingId == null && existingUser?.trainingId != null) {
          user = user.copyWith(trainingId: existingUser?.trainingId);
        }
        if (user.batchKe == null && existingUser?.batchKe != null) {
          user = user.copyWith(batchKe: existingUser?.batchKe);
        }
        if (user.trainingTitle == null && existingUser?.trainingTitle != null) {
          user = user.copyWith(trainingTitle: existingUser?.trainingTitle);
        }
        await StorageService.saveUserData(jsonEncode(user.toJson()));
        return user;
      }
    }
    throw Exception('Format data respon profil tidak sesuai');
  }

  Future<UserModel> updateProfile({
    required String name,
    String? email,
    String? jenisKelamin,
    dynamic batchId,
    dynamic trainingId,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
    };
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (jenisKelamin != null && jenisKelamin.isNotEmpty) {
      body['jenis_kelamin'] = jenisKelamin;
    }
    if (batchId != null) body['batch_id'] = batchId;
    if (trainingId != null) body['training_id'] = trainingId;

    final response = await _apiClient.put(
      ApiEndpoints.profile,
      body: body,
    );

    if (response is Map<String, dynamic> && response.containsKey('data')) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final userMap =
            (data.containsKey('user') && data['user'] is Map<String, dynamic>)
                ? data['user'] as Map<String, dynamic>
                : data;
        final existingRaw = StorageService.getUserData();
        UserModel? existingUser;
        if (existingRaw != null && existingRaw.isNotEmpty) {
          try {
            existingUser = UserModel.fromJson(jsonDecode(existingRaw));
          } catch (_) {}
        }
        var user = UserModel.fromJson(userMap);
        if (user.profilePhoto == null || user.profilePhoto!.isEmpty) {
          user = user.copyWith(profilePhoto: existingUser?.profilePhoto);
        }
        if (user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty) {
          user = user.copyWith(profilePhotoUrl: existingUser?.profilePhotoUrl);
        }
        if (user.createdAt == null || user.createdAt!.isEmpty) {
          user = user.copyWith(createdAt: existingUser?.createdAt);
        }
        if (user.batchKe == null && existingUser?.batchKe != null) {
          user = user.copyWith(batchKe: existingUser?.batchKe);
        }
        if (user.trainingTitle == null && existingUser?.trainingTitle != null) {
          user = user.copyWith(trainingTitle: existingUser?.trainingTitle);
        }
        await StorageService.saveUserData(jsonEncode(user.toJson()));
        return user;
      }
    }
    throw Exception('Gagal memperbarui profil');
  }

  Future<String> updateProfilePhoto(String base64DataUri) async {
    final response = await _apiClient.put(
      ApiEndpoints.profilePhoto,
      body: {'profile_photo': base64DataUri},
    );

    if (response is Map<String, dynamic>) {
      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          final val = data['profile_photo'] ??
              data['profile_photo_url'] ??
              data['photo'] ??
              data['url'] ??
              (data['user'] is Map ? data['user']['profile_photo'] : null);
          if (val != null && val.toString().isNotEmpty) {
            return val.toString();
          }
        } else if (data is String && data.isNotEmpty) {
          return data;
        }
      }
      final directVal = response['profile_photo'] ??
          response['profile_photo_url'] ??
          response['photo'] ??
          response['url'];
      if (directVal != null && directVal.toString().isNotEmpty) {
        return directVal.toString();
      }
    }
    return '';
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      ApiEndpoints.forgotPassword,
      withAuth: false,
      body: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.resetPassword,
      withAuth: false,
      body: {
        'email': email,
        'otp': otp,
        'password': newPassword,
      },
    );
  }

  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.login,
      withAuth: false,
      body: {'email': email, 'password': oldPassword},
    );
    try {
      await _apiClient.put(
        ApiEndpoints.profile,
        body: {'password': newPassword},
      );
    } catch (_) {}
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }
}
