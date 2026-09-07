import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/data/models/attendance_model.dart';
import 'package:absendulu/presentation/providers/history_provider.dart';
import 'package:absendulu/presentation/providers/theme_provider.dart';
import 'package:absendulu/presentation/screens/history/history_detail_sheet.dart';
import 'package:absendulu/presentation/widgets/neumorphic_card.dart';
import 'package:absendulu/presentation/widgets/neumorphic_skeleton.dart';
import 'package:absendulu/presentation/widgets/neumorphic_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = Provider.of<HistoryProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final filteredList = history.historyList.where((item) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Hadir') {
        return item.effectiveStatus == 'hadir' ||
            item.effectiveStatus == 'masuk';
      }
      if (_selectedFilter == 'Terlambat') {
        return item.effectiveStatus == 'terlambat' ||
            item.effectiveStatus == 'telat';
      }
      if (_selectedFilter == 'Izin') {
        return item.effectiveStatus == 'izin';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeumorphicCard(
                    isSmall: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    onTap: () async {
                      final now = DateTime.now();
                      final initial = history.currentMonth.isAfter(now)
                          ? now
                          : history.currentMonth;
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2024),
                        lastDate: now,
                      );
                      if (selected != null) {
                        history.changeMonth(selected);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatMonthYear(history.currentMonth),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textHighDark
                                : AppColors.textHigh,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _selectedFilter == 'Semua'
                        ? '${history.historyList.length} Catatan'
                        : '${filteredList.length} dari ${history.historyList.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMediumDark
                          : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => history.loadHistory(),
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                  children: [
                    _buildHeatmap(context, history, isDark),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Presensi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textHighDark
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (history.isLoading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: NeumorphicSkeleton.circle(size: 14),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFilterChips(context, history, isDark),
                    const SizedBox(height: 14),
                    if (history.isLoading && history.historyList.isEmpty)
                      const HistoryListSkeleton(itemCount: 4)
                    else if (history.historyList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy_rounded,
                                size: 52,
                                color: isDark
                                    ? AppColors.textLowDark
                                    : AppColors.textLow,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada catatan presensi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textMediumDark
                                      : AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data absensi bulan ini akan tampil di sini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textLowDark
                                      : AppColors.textLow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filteredList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.textLowDark
                                    : AppColors.textLow,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada presensi status $_selectedFilter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textMediumDark
                                      : AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba pilih filter status yang lain',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textLowDark
                                      : AppColors.textLow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredList.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NeumorphicCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) =>
                                    HistoryDetailSheet(attendance: item),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormatter.formatIndonesianDateString(
                                          item.attendanceDate,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    NeumorphicStatusChip(
                                      status: item.effectiveStatus,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.login_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Masuk: ${DateFormatter.formatTimeString(item.effectiveCheckInTime, isRoman: theme.isRomanClock)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.textHighDark
                                                  : AppColors.textHigh,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.logout_rounded,
                                            size: 14,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pulang: ${DateFormatter.formatTimeString(item.effectiveCheckOutTime, isRoman: theme.isRomanClock)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.textHighDark
                                                  : AppColors.textHigh,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.effectiveCoordinates != null &&
                                    item.effectiveCoordinates!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.my_location_rounded,
                                        size: 13,
                                        color: AppColors.textMedium,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.effectiveCoordinates!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.textMediumDark
                                                : AppColors.textMedium,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    HistoryProvider history,
    bool isDark,
  ) {
    final filters = [
      {
        'label': 'Semua',
        'count': history.historyList.length,
        'color': const Color(0xFF2C54D8),
        'textColor': Colors.white,
      },
      {
        'label': 'Hadir',
        'count': history.historyList
            .where(
              (item) =>
                  item.effectiveStatus == 'hadir' ||
                  item.effectiveStatus == 'masuk',
            )
            .length,
        'color': const Color(0xFF086842),
        'textColor': Colors.white,
      },
      {
        'label': 'Terlambat',
        'count': history.historyList
            .where(
              (item) =>
                  item.effectiveStatus == 'terlambat' ||
                  item.effectiveStatus == 'telat',
            )
            .length,
        'color': const Color(0xFFEA580C),
        'textColor': Colors.white,
      },
      {
        'label': 'Izin',
        'count': history.historyList
            .where((item) => item.effectiveStatus == 'izin')
            .length,
        'color': const Color(0xFFF6B155),
        'textColor': const Color(0xFF1E293B),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final color = f['color'] as Color;
          final textColor = f['textColor'] as Color;
          final isSelected = _selectedFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = label;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      )
                    : NeumorphicDecorations.extrudedSm(
                        isDark: isDark,
                        borderRadius: 14,
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSelected && label != 'Semua') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? textColor
                            : (isDark
                                  ? AppColors.textHighDark
                                  : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (label == 'Izin'
                                  ? Colors.black.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.25))
                            : (isDark
                                  ? const Color(0xFF222B3D)
                                  : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? textColor
                              : (isDark
                                    ? AppColors.textMediumDark
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeatmap(
    BuildContext context,
    HistoryProvider history,
    bool isDark,
  ) {
    final now = DateTime.now();
    final year = history.currentMonth.year;
    final month = history.currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final Map<int, AttendanceModel> attendanceByDay = {};
    for (final item in history.historyList) {
      if (item.attendanceDate != null) {
        final parsed = DateTime.tryParse(item.attendanceDate!);
        if (parsed != null) {
          if (parsed.year == year && parsed.month == month) {
            attendanceByDay[parsed.day] = item;
          }
        } else {
          try {
            final dateOnly = item.attendanceDate!.trim().split(' ').first;
            final parts = dateOnly.split('-');
            if (parts.length == 3) {
              final y = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              final d = int.parse(parts[2]);
              if (y == year && m == month) {
                attendanceByDay[d] = item;
              }
            }
          } catch (_) {}
        }
      }
    }

    final List<List<int?>> weeks = [];
    List<int?> currentWeek = List.filled(7, null);

    final startWeekday = firstDay.weekday;
    int day = 1;

    for (int i = startWeekday - 1; i < 7 && day <= daysInMonth; i++) {
      currentWeek[i] = day;
      day++;
    }
    weeks.add(currentWeek);

    while (day <= daysInMonth) {
      currentWeek = List.filled(7, null);
      for (int i = 0; i < 7 && day <= daysInMonth; i++) {
        currentWeek[i] = day;
        day++;
      }
      weeks.add(currentWeek);
    }

    return Container(
      decoration: NeumorphicDecorations.extruded(
        isDark: isDark,
        borderRadius: 24,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.apps_rounded,
                    size: 20,
                    color: Color(0xFF2C54D8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Heatmap Aktivitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textHighDark
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141A24) : const Color(0xFFE2EAF5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : const Color(0xFFA3B1C6).withValues(alpha: 0.4),
                  offset: const Offset(2, 2),
                  blurRadius: 5,
                ),
                BoxShadow(
                  color: isDark
                      ? const Color(0xFF222B3D).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.8),
                  offset: const Offset(-2, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 16,
              bottom: 8,
            ),
            child: Column(
              children: [
                Row(
                  children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN']
                      .map((dName) {
                        final isSunday = dName == 'MIN';
                        return Expanded(
                          child: Center(
                            child: Text(
                              dName,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isSunday
                                    ? (isDark
                                          ? const Color(0xFFF87171)
                                          : const Color(0xFFEF4444))
                                    : (isDark
                                          ? AppColors.textMediumDark
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 10),
                ...weeks.map(
                  (week) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final d = week[colIndex];
                        final isSunday = colIndex == 6;

                        if (isSunday) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              height: 38,
                              alignment: Alignment.center,
                              child: Text(
                                d != null ? d.toString().padLeft(2, '0') : '-',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: d != null
                                      ? (isDark
                                            ? const Color(0xFFF87171)
                                            : const Color(0xFFEF4444))
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          );
                        }

                        if (d == null) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              height: 38,
                              alignment: Alignment.center,
                              child: Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          );
                        }

                        final att = attendanceByDay[d];
                        final bool isIzin = att != null && att.isIzin;
                        final bool isTerlambat =
                            att != null &&
                            !att.isIzin &&
                            (att.isLate ||
                                att.effectiveStatus == 'terlambat' ||
                                att.effectiveStatus == 'telat');
                        final bool isHadir =
                            att != null &&
                            !att.isIzin &&
                            !isTerlambat &&
                            (att.isCheckedIn ||
                                att.effectiveStatus == 'hadir' ||
                                att.effectiveStatus == 'masuk');
                        final bool isToday =
                            now.year == year &&
                            now.month == month &&
                            now.day == d;

                        Color cellBgColor;
                        Color cellTextColor;
                        Border? cellBorder;
                        List<BoxShadow>? cellShadow;

                        if (isHadir) {
                          cellBgColor = const Color(0xFF086842);
                          cellTextColor = Colors.white;
                          cellShadow = [
                            BoxShadow(
                              color: const Color(
                                0xFF086842,
                              ).withValues(alpha: 0.35),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ];
                        } else if (isTerlambat) {
                          cellBgColor = const Color(0xFFEA580C);
                          cellTextColor = Colors.white;
                          cellShadow = [
                            BoxShadow(
                              color: const Color(
                                0xFFEA580C,
                              ).withValues(alpha: 0.35),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ];
                        } else if (isIzin) {
                          cellBgColor = const Color(0xFFF6B155);
                          cellTextColor = const Color(0xFF1E293B);
                          cellShadow = [
                            BoxShadow(
                              color: const Color(
                                0xFFF6B155,
                              ).withValues(alpha: 0.35),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ];
                        } else {
                          cellBgColor = isDark
                              ? const Color(0xFF1C2433)
                              : const Color(0xFFEDF2F9);
                          cellTextColor = isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8);
                          cellShadow = [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : const Color(
                                      0xFFA3B1C6,
                                    ).withValues(alpha: 0.35),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF26344A)
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ];
                        }

                        if (isToday) {
                          cellBorder = Border.all(
                            color: const Color(0xFF1E40AF),
                            width: 2,
                          );
                        }

                        return Expanded(
                          child: GestureDetector(
                            onTap: att != null
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          HistoryDetailSheet(attendance: att),
                                    );
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              height: 38,
                              decoration: BoxDecoration(
                                color: cellBgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: cellBorder,
                                boxShadow: cellShadow,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                d.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: cellTextColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF086842),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Hadir',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMediumDark
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Terlambat',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMediumDark
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6B155),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Izin',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMediumDark
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
