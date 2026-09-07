import 'dart:io';
import 'package:dio/dio.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/core/network/api_exception.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final withAuth = options.extra['withAuth'] ?? true;
          if (withAuth) {
            final token = StorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final dateHeader = response.headers.value('date');
          if (dateHeader != null && dateHeader.isNotEmpty) {
            try {
              final serverTime = HttpDate.parse(dateHeader);
              StorageService.saveLastKnownServerTime(serverTime);
            } catch (_) {}
          }
          return handler.next(response);
        },
      ),
    );
  }

  Never _handleDioException(DioException e) {
    String errorMessage = 'Gagal terhubung ke server';
    int? statusCode = e.response?.statusCode;
    dynamic errors;

    final isCertError = e.type == DioExceptionType.badCertificate ||
        e.error.toString().toLowerCase().contains('handshake') ||
        e.error.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
        (e.message?.contains('CERTIFICATE_VERIFY_FAILED') ?? false);
    final isNetError = !isCertError &&
        (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.error is SocketException);

    if (isCertError) {
      errorMessage = 'Gagal verifikasi keamanan (SSL/TLS). Waktu perangkat tidak sesuai, periksa tanggal dan jam Anda.';
    } else if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final body = e.response!.data as Map<String, dynamic>;
      if (body.containsKey('message') && body['message'] != null) {
        errorMessage = body['message'].toString();
      }
      if (body.containsKey('errors')) {
        errors = body['errors'];
        if (errors is Map<String, dynamic>) {
          final firstErrorList = errors.values.firstWhere(
            (v) => v is List && v.isNotEmpty,
            orElse: () => null,
          );
          if (firstErrorList != null && firstErrorList.isNotEmpty) {
            errorMessage = firstErrorList.first.toString();
          }
        }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Koneksi ke server batas waktu habis (timeout)';
    } else if (e.message != null && e.message!.isNotEmpty) {
      errorMessage = e.message!;
    }

    throw ApiException(
      message: errorMessage,
      statusCode: statusCode,
      errors: errors,
      isCertificateError: isCertError,
      isNetworkError: isNetError,
    );
  }

  Future<dynamic> get(
    String url, {
    bool withAuth = true,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal terhubung ke server: ${e.toString()}');
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    bool withAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal terhubung ke server: ${e.toString()}');
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    bool withAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: body,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal terhubung ke server: ${e.toString()}');
    }
  }

  Future<dynamic> delete(
    String url, {
    bool withAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        options: Options(
          headers: headers,
          extra: {'withAuth': withAuth},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Gagal terhubung ke server: ${e.toString()}');
    }
  }
}
