class ApiEndpoints {
  static const String baseUrl = 'https://appabsensi.mobileprojp.com/api';
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String resetPassword = '$baseUrl/reset-password';
  static const String profile = '$baseUrl/profile';
  static const String profilePhoto = '$baseUrl/profile/photo';
  static const String checkIn = '$baseUrl/absen/check-in';
  static const String checkOut = '$baseUrl/absen/check-out';
  static const String izin = '$baseUrl/izin';
  static const String today = '$baseUrl/absen/today';
  static const String stats = '$baseUrl/absen/stats';
  static const String history = '$baseUrl/absen/history';
  static const String batches = '$baseUrl/batches';
  static const String trainings = '$baseUrl/trainings';
  static String deleteAbsen(int id) => '$baseUrl/absen/$id';
}

