import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/data/models/attendance_model.dart';
import 'package:absendulu/data/repositories/attendance_repository.dart';
import 'package:absendulu/presentation/providers/theme_provider.dart';
import 'package:absendulu/presentation/widgets/neumorphic_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttendanceStatsDetailScreen extends StatefulWidget {
  const AttendanceStatsDetailScreen({super.key});

  @override
  State<AttendanceStatsDetailScreen> createState() =>
      _AttendanceStatsDetailScreenState();
}

class _AttendanceStatsDetailScreenState
    extends State<AttendanceStatsDetailScreen> {
  final AttendanceRepository _repository = AttendanceRepository();
  DateTime _selectedMonth = DateTime.now();
  bool _isAllTime = false;
  List<AttendanceModel> _detailList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<AttendanceModel> fresh;
      if (_isAllTime) {
        fresh = await _repository.getHistory();
      } else {
        final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
        fresh = await _repository.getHistory(
          startDate: DateFormatter.formatApiDate(start),
          endDate: DateFormatter.formatApiDate(end),
        );
      }
      if (mounted) {
        setState(() {
          _detailList = fresh;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final initial = _selectedMonth.isAfter(now) ? now : _selectedMonth;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
        _isAllTime = false;
      });
      _loadData();
    } else if (_isAllTime) {
      setState(() => _isAllTime = false);
      _loadData();
    }
  }

  void _selectAllTime() {
    if (_isAllTime) return;
    setState(() => _isAllTime = true);
    _loadData();
  }

  int? _timeToMinutes(String timeStr) {
    if (timeStr == '--:--' || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return h * 60 + m;
      }
    } catch (_) {}
    return null;
  }

  String _minutesToTimeString(int totalMinutes, {bool isRoman = false}) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (isRoman) {
      return '${DateFormatter.toRoman(h)}:${DateFormatter.toRoman(m)}';
    }
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static final List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  String _formatShortDate(String? dateStr) {
    final dt = _parseDate(dateStr);
    if (dt == null) return '-';
    final m = _shortMonths[dt.month - 1];
    return '${dt.day} $m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Provider.of<ThemeProvider>(context);
    final isRoman = theme.isRomanClock;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double fontScale = screenWidth < 360
        ? 0.86
        : (screenWidth < 400 ? 0.94 : 1.0);

    final historyList = _detailList;

    final totalTerlambat = historyList
        .where(
          (item) =>
              item.effectiveStatus == 'terlambat' ||
              item.effectiveStatus == 'telat',
        )
        .length;
    final totalHadir = historyList
        .where(
          (item) =>
              item.effectiveStatus == 'hadir' ||
              item.effectiveStatus == 'masuk',
        )
        .length;
    final totalIzin = historyList.where((item) => item.isIzin).length;

    final totalAttended = totalHadir + totalTerlambat;
    final double onTimePercentage = totalAttended > 0
        ? (totalHadir / totalAttended) * 100
        : 0.0;

    final validCheckInMinutes = <int>[];
    final validCheckOutMinutes = <int>[];

    int? fastestInMinutes;
    String? fastestInDate;

    int? latestOutMinutes;
    String? latestOutDate;

    final dayCheckIns = <int, List<int>>{1: [], 2: [], 3: [], 4: [], 5: []};

    for (final item in historyList) {
      if (item.isIzin) continue;

      final inMin = _timeToMinutes(item.effectiveCheckInTime);
      if (inMin != null) {
        validCheckInMinutes.add(inMin);

        if (fastestInMinutes == null || inMin < fastestInMinutes) {
          fastestInMinutes = inMin;
          fastestInDate = item.attendanceDate;
        }

        final dt = _parseDate(item.attendanceDate);
        if (dt != null && dayCheckIns.containsKey(dt.weekday)) {
          dayCheckIns[dt.weekday]!.add(inMin);
        }
      }

      if (item.isCheckedOut) {
        final outMin = _timeToMinutes(item.effectiveCheckOutTime);
        if (outMin != null) {
          validCheckOutMinutes.add(outMin);

          if (latestOutMinutes == null || outMin > latestOutMinutes) {
            latestOutMinutes = outMin;
            latestOutDate = item.attendanceDate;
          }
        }
      }
    }

    final String avgCheckInStr;
    final String avgCheckInDiff;
    if (validCheckInMinutes.isNotEmpty) {
      final avgMin =
          (validCheckInMinutes.reduce((a, b) => a + b) /
                  validCheckInMinutes.length)
              .round();
      avgCheckInStr = _minutesToTimeString(avgMin, isRoman: isRoman);
      final diff = 480 - avgMin;
      if (diff > 0) {
        avgCheckInDiff = '$diff mnt lebih awal';
      } else if (diff < 0) {
        avgCheckInDiff = '${diff.abs()} mnt terlambat';
      } else {
        avgCheckInDiff =
            'Tepat ${DateFormatter.formatTimeString('08:00', isRoman: isRoman)} WIB';
      }
    } else {
      avgCheckInStr = '--:--';
      avgCheckInDiff =
          'Target ${DateFormatter.formatTimeString('08:00', isRoman: isRoman)} WIB';
    }

    final String avgCheckOutStr;
    final String avgCheckOutDiff;
    if (validCheckOutMinutes.isNotEmpty) {
      final avgMin =
          (validCheckOutMinutes.reduce((a, b) => a + b) /
                  validCheckOutMinutes.length)
              .round();
      avgCheckOutStr = _minutesToTimeString(avgMin, isRoman: isRoman);
      final diff = avgMin - 900;
      if (diff > 0) {
        avgCheckOutDiff = '+$diff mnt di lokasi';
      } else if (diff < 0) {
        avgCheckOutDiff = '${diff.abs()} mnt lebih awal';
      } else {
        avgCheckOutDiff =
            'Tepat ${DateFormatter.formatTimeString('15:00', isRoman: isRoman)} WIB';
      }
    } else {
      avgCheckOutStr = '--:--';
      avgCheckOutDiff =
          'Target ${DateFormatter.formatTimeString('15:00', isRoman: isRoman)} WIB';
    }

    final fastestInStr = fastestInMinutes != null
        ? _minutesToTimeString(fastestInMinutes, isRoman: isRoman)
        : '--:--';
    final latestOutStr = latestOutMinutes != null
        ? _minutesToTimeString(latestOutMinutes, isRoman: isRoman)
        : '--:--';

    String bestDayName = 'Senin';
    int? bestDayAvgMin;
    final dayNames = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
    };

    for (final entry in dayCheckIns.entries) {
      if (entry.value.isNotEmpty) {
        final avg = (entry.value.reduce((a, b) => a + b) / entry.value.length)
            .round();
        if (bestDayAvgMin == null || avg < bestDayAvgMin) {
          bestDayAvgMin = avg;
          bestDayName = dayNames[entry.key] ?? 'Senin';
        }
      }
    }

    final String funFactText;
    if (bestDayAvgMin != null && bestDayAvgMin <= 8) {
      funFactText =
          'Anda paling sering check-in lebih awal di hari $bestDayName (rata-rata ${_minutesToTimeString(bestDayAvgMin, isRoman: isRoman)} WIB). Konsistensi yang hebat!';
    } else {
      funFactText =
          'Check-in sebelum pukul ${DateFormatter.formatTimeString('08:00', isRoman: isRoman)} WIB setiap hari untuk menjaga rekor kehadiran sempurna dan memaksimalkan pelatihan Anda!';
    }

    final String motivationText;
    final Color onTimeColor;
    if (totalAttended == 0) {
      motivationText = 'Belum ada catatan presensi pada periode ini';
      onTimeColor = isDark ? AppColors.textMediumDark : const Color(0xFF94A3B8);
    } else if (onTimePercentage >= 90) {
      motivationText = 'Anda sangat disiplin bulan ini!';
      onTimeColor = const Color(0xFF10B981);
    } else if (onTimePercentage >= 75) {
      motivationText = 'Konsistensi Anda cukup baik, pertahankan!';
      onTimeColor = const Color(0xFFF59E0B);
    } else {
      motivationText = 'Tingkatkan kehadiran tepat waktu Anda!';
      onTimeColor = const Color(0xFFEA580C);
    }

    final currentPeriodStr = _isAllTime
        ? 'Semua Periode'
        : DateFormatter.formatMonthYear(_selectedMonth);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: NeumorphicDecorations.extrudedSm(
                          isDark: isDark,
                          borderRadius: 12,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.textHighDark
                              : AppColors.textHigh,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Insight Kehadiran',
                            style: TextStyle(
                              fontSize: 19 * fontScale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppColors.textHighDark
                                  : AppColors.textHigh,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentPeriodStr,
                            style: TextStyle(
                              fontSize: 11.5 * fontScale,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMediumDark
                                  : AppColors.textMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isAllTime) {
                            setState(() => _isAllTime = false);
                            _loadData();
                          } else {
                            _pickMonth();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: !_isAllTime
                              ? NeumorphicDecorations.primaryPill(
                                  borderRadius: 12,
                                )
                              : NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 12,
                                ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 15,
                                color: !_isAllTime
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textHighDark
                                          : AppColors.textHigh),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_shortMonths[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                                  style: TextStyle(
                                    fontSize: 12 * fontScale,
                                    fontWeight: FontWeight.w700,
                                    color: !_isAllTime
                                        ? Colors.white
                                        : (isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: !_isAllTime
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textMediumDark
                                          : AppColors.textMedium),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectAllTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: _isAllTime
                              ? NeumorphicDecorations.primaryPill(
                                  borderRadius: 12,
                                )
                              : NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 12,
                                ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Semua',
                                style: TextStyle(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.w700,
                                  color: _isAllTime
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.textHighDark
                                            : AppColors.textHigh),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (_isLoading && _detailList.isEmpty)
                  _buildSkeletonLayout(isDark, fontScale)
                else ...[
                  Container(
                    decoration: NeumorphicDecorations.extruded(
                      isDark: isDark,
                      borderRadius: 22,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ON-TIME PERCENTAGE',
                                    style: TextStyle(
                                      fontSize: 9.5 * fontScale,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: onTimeColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${onTimePercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 34 * fontScale,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                      color: isDark
                                          ? AppColors.textHighDark
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    motivationText,
                                    style: TextStyle(
                                      fontSize: 12.5 * fontScale,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textMediumDark
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 88,
                              height: 88,
                              decoration: NeumorphicDecorations.extruded(
                                isDark: isDark,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: CircularProgressIndicator(
                                      value: (onTimePercentage / 100).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      strokeWidth: 7,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor: isDark
                                          ? const Color(0xFF222B3D)
                                          : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        onTimeColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.timer_rounded,
                                    size: 28,
                                    color: onTimeColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard(
                                label: 'Tepat Waktu',
                                value: '$totalHadir',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                                fontScale: fontScale,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatCard(
                                label: 'Terlambat',
                                value: '$totalTerlambat',
                                color: const Color(0xFFEA580C),
                                isDark: isDark,
                                fontScale: fontScale,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatCard(
                                label: 'Izin',
                                value: '$totalIzin',
                                color: const Color(0xFFF59E0B),
                                isDark: isDark,
                                fontScale: fontScale,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      'Analisis Waktu Kehadiran',
                      style: TextStyle(
                        fontSize: 15 * fontScale,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textHighDark
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeMetricCard(
                          title: 'Rata-Rata Masuk',
                          value: avgCheckInStr,
                          subtitle: avgCheckInDiff,
                          icon: Icons.login_rounded,
                          accentColor: const Color(0xFF0284C7),
                          isDark: isDark,
                          fontScale: fontScale,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeMetricCard(
                          title: 'Rata-Rata Pulang',
                          value: avgCheckOutStr,
                          subtitle: avgCheckOutDiff,
                          icon: Icons.logout_rounded,
                          accentColor: const Color(0xFF4F46E5),
                          isDark: isDark,
                          fontScale: fontScale,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeMetricCard(
                          title: 'In Tercepat',
                          value: fastestInStr,
                          subtitle: fastestInDate != null
                              ? _formatShortDate(fastestInDate)
                              : 'Rekor Masuk',
                          icon: Icons.bolt_rounded,
                          accentColor: const Color(0xFF10B981),
                          isDark: isDark,
                          fontScale: fontScale,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeMetricCard(
                          title: 'Out Terlama',
                          value: latestOutStr,
                          subtitle: latestOutDate != null
                              ? _formatShortDate(latestOutDate)
                              : 'Rekor Pulang',
                          icon: Icons.nightlight_round,
                          accentColor: const Color(0xFFF59E0B),
                          isDark: isDark,
                          fontScale: fontScale,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: NeumorphicDecorations.extruded(
                      isDark: isDark,
                      borderRadius: 22,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distribusi Kehadiran',
                              style: TextStyle(
                                fontSize: 14.5 * fontScale,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textHighDark
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${totalAttended + totalIzin} Total Catatan',
                              style: TextStyle(
                                fontSize: 11 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMediumDark
                                    : AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 14,
                            decoration: NeumorphicDecorations.insetWell(
                              isDark: isDark,
                              borderRadius: 10,
                            ),
                            child: (totalAttended + totalIzin) == 0
                                ? Container(
                                    color: isDark
                                        ? const Color(0xFF232D3F)
                                        : const Color(0xFFE2E8F0),
                                  )
                                : Row(
                                    children: [
                                      if (totalHadir > 0)
                                        Expanded(
                                          flex: totalHadir,
                                          child: Container(
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      if (totalTerlambat > 0)
                                        Expanded(
                                          flex: totalTerlambat,
                                          child: Container(
                                            color: const Color(0xFFEA580C),
                                          ),
                                        ),
                                      if (totalIzin > 0)
                                        Expanded(
                                          flex: totalIzin,
                                          child: Container(
                                            color: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLegendItem(
                              label: 'Tepat Waktu',
                              count: totalHadir,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                              fontScale: fontScale,
                            ),
                            _buildLegendItem(
                              label: 'Terlambat',
                              count: totalTerlambat,
                              color: const Color(0xFFEA580C),
                              isDark: isDark,
                              fontScale: fontScale,
                            ),
                            _buildLegendItem(
                              label: 'Izin',
                              count: totalIzin,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                              fontScale: fontScale,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: NeumorphicDecorations.extruded(
                      isDark: isDark,
                      borderRadius: 22,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              size: 22,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'FUN FACT KEHADIRAN',
                              style: TextStyle(
                                fontSize: 10.5 * fontScale,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          funFactText,
                          style: TextStyle(
                            fontSize: 13 * fontScale,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMediumDark
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required double fontScale,
  }) {
    return Container(
      decoration: NeumorphicDecorations.extrudedSm(
        isDark: isDark,
        borderRadius: 14,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5 * fontScale,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMediumDark : AppColors.textMedium,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 19 * fontScale,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hari',
            style: TextStyle(
              fontSize: 9.5 * fontScale,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textLowDark : AppColors.textLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required double fontScale,
  }) {
    return Container(
      decoration: NeumorphicDecorations.extruded(
        isDark: isDark,
        borderRadius: 18,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5 * fontScale,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMediumDark : AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22 * fontScale,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? AppColors.textHighDark : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
    required double fontScale,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11 * fontScale,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMediumDark : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLayout(bool isDark, double fontScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: NeumorphicDecorations.extruded(
            isDark: isDark,
            borderRadius: 22,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        NeumorphicSkeleton(
                          width: 110,
                          height: 12,
                          borderRadius: 4,
                        ),
                        SizedBox(height: 12),
                        NeumorphicSkeleton(
                          width: 80,
                          height: 34,
                          borderRadius: 8,
                        ),
                        SizedBox(height: 10),
                        NeumorphicSkeleton(
                          width: 160,
                          height: 14,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const NeumorphicSkeleton.circle(size: 80),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(
                    child: NeumorphicSkeleton(height: 64, borderRadius: 14),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: NeumorphicSkeleton(height: 64, borderRadius: 14),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: NeumorphicSkeleton(height: 64, borderRadius: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const NeumorphicSkeleton(width: 160, height: 16, borderRadius: 4),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: NeumorphicSkeleton(height: 95, borderRadius: 18)),
            SizedBox(width: 12),
            Expanded(child: NeumorphicSkeleton(height: 95, borderRadius: 18)),
          ],
        ),
        const SizedBox(height: 22),
        const NeumorphicSkeleton(width: 140, height: 16, borderRadius: 4),
        const SizedBox(height: 14),
        Container(
          decoration: NeumorphicDecorations.extruded(
            isDark: isDark,
            borderRadius: 20,
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: const [
              NeumorphicSkeleton(height: 20, borderRadius: 6),
              SizedBox(height: 16),
              NeumorphicSkeleton(height: 18, borderRadius: 6),
              SizedBox(height: 16),
              NeumorphicSkeleton(height: 18, borderRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
