import 'package:intl/intl.dart';

class DateFormatter {
  static final List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String formatIndonesianDate(DateTime date) {
    final dayName = _days[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final monthName = _months[date.month - 1];
    final year = date.year.toString();
    return '$dayName, $day $monthName $year';
  }

  static String formatMonthYear(DateTime date) {
    final monthName = _months[date.month - 1];
    return '$monthName ${date.year}';
  }

  static String formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatApiTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDisplayTime(DateTime date) {
    return '${DateFormat('HH:mm:ss').format(date)} WIB';
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatIndonesianDateString(
    String? dateStr, {
    String fallback = 'Presensi',
  }) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return fallback;
    }
    try {
      final trimmed = dateStr.trim();
      final dateOnly =
          trimmed.contains(' ') ? trimmed.split(' ').first : trimmed;
      final parsed = DateTime.tryParse(dateOnly);
      if (parsed != null) {
        return formatIndonesianDate(parsed);
      }
    } catch (_) {}
    return dateStr;
  }
}

