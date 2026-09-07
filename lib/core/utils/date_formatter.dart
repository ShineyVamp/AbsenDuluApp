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

  static String toRoman(int number) {
    if (number <= 0) return 'N';
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I',
    ];
    final buffer = StringBuffer();
    var num = number;
    for (var i = 0; i < values.length; i++) {
      while (num >= values[i]) {
        buffer.write(symbols[i]);
        num -= values[i];
      }
    }
    return buffer.toString();
  }

  static String formatTimeString(String? timeStr, {bool isRoman = false}) {
    if (timeStr == null ||
        timeStr.trim().isEmpty ||
        timeStr == '--:--' ||
        timeStr == '-') {
      return timeStr ?? '--:--';
    }
    if (!isRoman) return timeStr;
    final parts = timeStr.trim().split(':');
    if (parts.isEmpty) return timeStr;
    final romanParts = <String>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed != null) {
        romanParts.add(toRoman(parsed));
      } else {
        romanParts.add(part);
      }
    }
    return romanParts.join(':');
  }

  static String formatTime(
    DateTime date, {
    bool isRoman = false,
    bool includeSeconds = false,
  }) {
    if (!isRoman) {
      return includeSeconds
          ? DateFormat('HH:mm:ss').format(date)
          : DateFormat('HH:mm').format(date);
    }
    final h = toRoman(date.hour);
    final m = toRoman(date.minute);
    if (includeSeconds) {
      final s = toRoman(date.second);
      return '$h:$m:$s';
    }
    return '$h:$m';
  }

  static String formatDisplayTime(DateTime date, {bool isRoman = false}) {
    return '${formatTime(date, isRoman: isRoman, includeSeconds: true)} WIB';
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

