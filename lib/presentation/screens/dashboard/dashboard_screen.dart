import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/providers/attendance_provider.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/providers/history_provider.dart';
import 'package:absendulu/presentation/providers/theme_provider.dart';
import 'package:absendulu/presentation/screens/attendance/gps_verification_screen.dart';
import 'package:absendulu/presentation/screens/attendance/leave_request_dialog.dart';
import 'package:absendulu/presentation/screens/dashboard/attendance_stats_detail_screen.dart';
import 'package:absendulu/presentation/widgets/custom_snackbar.dart';
import 'package:absendulu/presentation/widgets/neumorphic_card.dart';
import 'package:absendulu/presentation/widgets/neumorphic_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _toRoman(int number) => DateFormatter.toRoman(number);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final attendance = Provider.of<AttendanceProvider>(context);
    final historyProv = Provider.of<HistoryProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final double fontScale = screenWidth < 360
        ? 0.86
        : (screenWidth < 400 ? 0.94 : 1.0);

    final userName = auth.user?.name ?? 'Siswa PPKD';
    final stats = attendance.stats;
    final today = attendance.todayAttendance;
    final bool isTodayLoading =
        attendance.isLoading || (attendance.isTodayLoading && today == null);
    final bool isStatsLoading =
        attendance.isLoading ||
        attendance.isStatsLoading ||
        (historyProv.isLoading && historyProv.historyList.isEmpty);
    final bool isDashboardLoading = isTodayLoading || isStatsLoading;

    final now = DateTime.now();
    final currentYearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonthRecords = historyProv.currentMonthHistoryList.where((
      item,
    ) {
      if (item.attendanceDate != null && item.attendanceDate!.isNotEmpty) {
        return item.attendanceDate!.startsWith(currentYearMonth);
      }
      return true;
    }).toList();

    final totalTerlambat = currentMonthRecords
        .where(
          (item) =>
              item.effectiveStatus == 'terlambat' ||
              item.effectiveStatus == 'telat',
        )
        .length;
    final totalHadirFromHistory = currentMonthRecords
        .where(
          (item) =>
              item.effectiveStatus == 'hadir' ||
              item.effectiveStatus == 'masuk',
        )
        .length;
    final totalHadir = currentMonthRecords.isNotEmpty
        ? totalHadirFromHistory
        : (stats.totalMasuk >= totalTerlambat
              ? (stats.totalMasuk - totalTerlambat)
              : stats.totalMasuk);
    final totalIzinFromHistory = currentMonthRecords
        .where((item) => item.isIzin || item.effectiveStatus == 'izin')
        .length;
    final totalIzin = currentMonthRecords.isNotEmpty
        ? totalIzinFromHistory
        : stats.totalIzin;

    final isIzin = today != null && today.isIzin;
    final hasCheckedIn = today != null && today.isCheckedIn;
    final hasCheckedOut = today != null && today.isCheckedOut;
    final isLate =
        attendance.currentTime.hour > 8 ||
        (attendance.currentTime.hour == 8 &&
            (attendance.currentTime.minute > 0 ||
                attendance.currentTime.second > 0));

    final bool reminderInEnabled = StorageService.getReminderCheckIn();
    final bool reminderOutEnabled = StorageService.getReminderCheckOut();
    final int currentHour = attendance.currentTime.hour;
    final int currentMinute = attendance.currentTime.minute;
    final bool isMorningReminderTime =
        (currentHour == 7 && currentMinute >= 30) ||
        (currentHour == 8 && currentMinute <= 15);
    final bool isAfternoonReminderTime = currentHour >= 15;
    final bool showMorningReminder =
        reminderInEnabled && !hasCheckedIn && isMorningReminderTime;
    final bool showAfternoonReminder =
        reminderOutEnabled &&
        hasCheckedIn &&
        !hasCheckedOut &&
        isAfternoonReminderTime;

    Color buttonColor;
    String mainButtonText = 'Absen';
    String subButtonText;
    bool isCheckInAction = true;

    if (isTodayLoading) {
      buttonColor = const Color(0xFF2C54D8);
      mainButtonText = 'Memuat';
      subButtonText = 'MEMERIKSA DATA';
    } else if (isIzin) {
      buttonColor = AppColors.warning;
      mainButtonText = 'Izin';
      subButtonText = 'SEDANG IZIN';
    } else if (!hasCheckedIn) {
      isCheckInAction = true;
      if (isLate) {
        buttonColor = const Color(0xFFF59E0B);
        mainButtonText = 'Absen';
        subButtonText = 'TERLAMBAT';
      } else {
        buttonColor = const Color(0xFF2C54D8);
        mainButtonText = 'Absen';
        subButtonText = 'ABSEN MASUK';
      }
    } else if (!hasCheckedOut) {
      isCheckInAction = false;
      buttonColor = Colors.redAccent;
      mainButtonText = 'Pulang';
      subButtonText = 'ABSEN PULANG';
    } else {
      buttonColor = const Color(0xFF64748B);
      mainButtonText = 'Selesai';
      subButtonText = 'SUDAH PULANG';
    }

    final String checkInTimeDisplay = today != null && today.isCheckedIn
        ? DateFormatter.formatTimeString(
            today.effectiveCheckInTime,
            isRoman: theme.isRomanClock,
          )
        : '--:--';
    final String checkOutTimeDisplay = today != null && today.isCheckedOut
        ? DateFormatter.formatTimeString(
            today.effectiveCheckOutTime,
            isRoman: theme.isRomanClock,
          )
        : '--:--';

    final String checkInStatusText;
    final Color checkInStatusColor;
    if (isIzin) {
      checkInStatusText = 'Izin';
      checkInStatusColor = AppColors.warning;
    } else if (hasCheckedIn) {
      if (today.isLate) {
        checkInStatusText = 'Terlambat';
        checkInStatusColor = const Color(0xFFF59E0B);
      } else {
        checkInStatusText = 'Tepat Waktu';
        checkInStatusColor = AppColors.success;
      }
    } else {
      checkInStatusText = 'Belum Masuk';
      checkInStatusColor = isDark
          ? AppColors.textMediumDark
          : AppColors.textMedium;
    }

    final String checkOutStatusText;
    final Color checkOutStatusColor;
    if (isIzin) {
      checkOutStatusText = 'Izin';
      checkOutStatusColor = AppColors.warning;
    } else if (hasCheckedOut) {
      checkOutStatusText = 'Selesai';
      checkOutStatusColor = AppColors.success;
    } else if (hasCheckedIn) {
      checkOutStatusText = 'Belum Pulang';
      checkOutStatusColor = const Color(0xFFF59E0B);
    } else {
      checkOutStatusText = 'Belum Masuk';
      checkOutStatusColor = isDark
          ? AppColors.textMediumDark
          : AppColors.textMedium;
    }

    void handleAttendanceTap() async {
      if (isTodayLoading) return;
      await context.push(GpsVerificationScreen(isCheckIn: isCheckInAction));
      await Future.wait([
        attendance.loadTodayAttendance(),
        attendance.loadStats(),
        historyProv.refreshCurrentMonth(),
      ]);
    }

    final String hourMinuteStr;
    final String secondStr;
    if (theme.isRomanClock) {
      hourMinuteStr =
          '${_toRoman(attendance.currentTime.hour)}:${_toRoman(attendance.currentTime.minute)}';
      secondStr = _toRoman(attendance.currentTime.second);
    } else {
      hourMinuteStr = DateFormat('HH:mm').format(attendance.currentTime);
      secondStr = DateFormat('ss').format(attendance.currentTime);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              attendance.initDashboard(),
              historyProv.refreshCurrentMonth(),
            ]);
          },
          color: AppColors.primary,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $userName',
                              style: TextStyle(
                                fontSize: 30 * fontScale,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textHighDark
                                    : AppColors.textHigh,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormatter.formatIndonesianDate(
                                DateTime.now(),
                              ),
                              style: TextStyle(
                                fontSize: 13 * fontScale,
                                color: isDark
                                    ? AppColors.textMediumDark
                                    : AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => theme.toggleTheme(!theme.isDarkMode),
                        icon: Icon(
                          theme.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (attendance.hasPendingOffline) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEA580C,
                              ).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              size: 18,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${attendance.pendingOfflineCount} Presensi Belum Sinkron',
                                  style: TextStyle(
                                    fontSize: 12.5 * fontScale,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tersimpan offline. Sinkronkan sekarang ke server.',
                                  style: TextStyle(
                                    fontSize: 11 * fontScale,
                                    color: isDark
                                        ? AppColors.textMediumDark
                                        : AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final count = await attendance
                                  .syncOfflineAttendance();
                              if (context.mounted) {
                                if (count > 0) {
                                  await Future.wait([
                                    attendance.loadStats(),
                                    historyProv.refreshCurrentMonth(),
                                  ]);
                                  CustomSnackBar.showSuccess(
                                    context,
                                    '$count presensi offline berhasil disinkronkan',
                                  );
                                } else {
                                  CustomSnackBar.showWarning(
                                    context,
                                    'Tidak dapat terhubung ke server',
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Sync',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  NeumorphicCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                attendance.isInsideGeofence
                                    ? 'Lokasi Sesuai: Radius ${attendance.distanceToPpkd.toStringAsFixed(0)}m dari PPKD Jakpus'
                                    : 'Di Luar Radius: ${attendance.distanceToPpkd.toStringAsFixed(0)}m dari PPKD Jakpus (Maks 300m)',
                                style: TextStyle(
                                  fontSize: 12 * fontScale,
                                  fontWeight: FontWeight.w700,
                                  color: attendance.isInsideGeofence
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                hourMinuteStr,
                                style: TextStyle(
                                  fontSize:
                                      (theme.isRomanClock ? 30 : 38) *
                                      fontScale,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: theme.isRomanClock ? 0.8 : 1.2,
                                  color: isDark
                                      ? AppColors.textHighDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                ':$secondStr',
                                style: TextStyle(
                                  fontSize:
                                      (theme.isRomanClock ? 30 : 38) *
                                      fontScale,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: theme.isRomanClock ? 0.8 : 1.2,
                                  color: const Color(0xFF2C54D8),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WIB',
                                style: TextStyle(
                                  fontSize:
                                      (theme.isRomanClock ? 26 : 38) *
                                      fontScale,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textMediumDark
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jadwal Masuk: ${DateFormatter.formatTimeString('08:00', isRoman: theme.isRomanClock)} WIB',
                          style: TextStyle(
                            fontSize: 12 * fontScale,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMediumDark
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 22),
                        GestureDetector(
                          onTap: handleAttendanceTap,
                          child: Container(
                            width: 196,
                            height: 196,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF1E2838)
                                  : const Color(0xFFEAF0FA),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : const Color(
                                          0xFFA6BEDD,
                                        ).withValues(alpha: 0.45),
                                  offset: const Offset(6, 6),
                                  blurRadius: 18,
                                ),
                                BoxShadow(
                                  color: isDark
                                      ? const Color(
                                          0xFF26344A,
                                        ).withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.95),
                                  offset: const Offset(-6, -6),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: buttonColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: buttonColor.withValues(alpha: 0.4),
                                      offset: const Offset(0, 6),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isTodayLoading) ...[
                                      const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'MEMERIKSA...',
                                        style: TextStyle(
                                          fontSize: 10 * fontScale,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        mainButtonText,
                                        style: TextStyle(
                                          fontSize: 24 * fontScale,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subButtonText,
                                        style: TextStyle(
                                          fontSize: 10 * fontScale,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          size: 16,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 12 * fontScale,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textMediumDark
                                                : AppColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (isTodayLoading) ...[
                                      const NeumorphicSkeleton(
                                        width: 65,
                                        height: 20,
                                        borderRadius: 5,
                                      ),
                                      const SizedBox(height: 5),
                                      const NeumorphicSkeleton(
                                        width: 75,
                                        height: 12,
                                        borderRadius: 4,
                                      ),
                                    ] else ...[
                                      Text(
                                        checkInTimeDisplay,
                                        style: TextStyle(
                                          fontSize: 18 * fontScale,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        checkInStatusText,
                                        style: TextStyle(
                                          fontSize: 11 * fontScale,
                                          fontWeight: FontWeight.w600,
                                          color: checkInStatusColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.logout_rounded,
                                          size: 16,
                                          color: Color(0xFF2C54D8),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pulang',
                                          style: TextStyle(
                                            fontSize: 12 * fontScale,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textMediumDark
                                                : AppColors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (isTodayLoading) ...[
                                      const NeumorphicSkeleton(
                                        width: 65,
                                        height: 20,
                                        borderRadius: 5,
                                      ),
                                      const SizedBox(height: 5),
                                      const NeumorphicSkeleton(
                                        width: 75,
                                        height: 12,
                                        borderRadius: 4,
                                      ),
                                    ] else ...[
                                      Text(
                                        checkOutTimeDisplay,
                                        style: TextStyle(
                                          fontSize: 18 * fontScale,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        checkOutStatusText,
                                        style: TextStyle(
                                          fontSize: 11 * fontScale,
                                          fontWeight: FontWeight.w600,
                                          color: checkOutStatusColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeumorphicCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => const LeaveRequestDialog(),
                      );
                      if (context.mounted) {
                        await Future.wait([
                          attendance.loadTodayAttendance(),
                          attendance.loadStats(),
                          historyProv.refreshCurrentMonth(),
                        ]);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Color(0xFFF59E0B),
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengajuan Izin & Sakit',
                                style: TextStyle(
                                  fontSize: 15 * fontScale,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textHighDark
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Berhalangan hadir? Ajukan permohonan resmi di sini',
                                style: TextStyle(
                                  fontSize: 11.5 * fontScale,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textMediumDark
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 20,
                                  color: Color(0xFF2C54D8),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Statistik Kehadiran',
                                  style: TextStyle(
                                    fontSize: 16 * fontScale,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textHighDark
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AttendanceStatsDetailScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Detail',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C54D8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'bulan ini',
                          style: TextStyle(
                            fontSize: 11.5 * fontScale,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.textMediumDark
                                : AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 6,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Hadir',
                                      style: TextStyle(
                                        fontSize: 11.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isDashboardLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: NeumorphicSkeleton(
                                          width: 35,
                                          height: 22,
                                          borderRadius: 6,
                                        ),
                                      )
                                    else
                                      Text(
                                        '$totalHadir',
                                        style: TextStyle(
                                          fontSize: 22 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalHadir Hari',
                                      style: TextStyle(
                                        fontSize: 10.5 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 6,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Terlambat',
                                      style: TextStyle(
                                        fontSize: 11.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEA580C),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isDashboardLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: NeumorphicSkeleton(
                                          width: 35,
                                          height: 22,
                                          borderRadius: 6,
                                        ),
                                      )
                                    else
                                      Text(
                                        '$totalTerlambat',
                                        style: TextStyle(
                                          fontSize: 22 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalTerlambat Hari',
                                      style: TextStyle(
                                        fontSize: 10.5 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 6,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Izin',
                                      style: TextStyle(
                                        fontSize: 11.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isDashboardLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: NeumorphicSkeleton(
                                          width: 35,
                                          height: 22,
                                          borderRadius: 6,
                                        ),
                                      )
                                    else
                                      Text(
                                        '$totalIzin',
                                        style: TextStyle(
                                          fontSize: 22 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalIzin Hari',
                                      style: TextStyle(
                                        fontSize: 10.5 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 10,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Jumlah Masuk',
                                      style: TextStyle(
                                        fontSize: 11.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textHighDark
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isDashboardLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: NeumorphicSkeleton(
                                          width: 44,
                                          height: 22,
                                          borderRadius: 6,
                                        ),
                                      )
                                    else
                                      Text(
                                        '${stats.totalMasuk}',
                                        style: TextStyle(
                                          fontSize: 22 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total Sesi Hadir',
                                      style: TextStyle(
                                        fontSize: 10.5 * fontScale,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: NeumorphicDecorations.extrudedSm(
                                  isDark: isDark,
                                  borderRadius: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 10,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Persentase Hadir',
                                      style: TextStyle(
                                        fontSize: 11.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textHighDark
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isDashboardLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: NeumorphicSkeleton(
                                          width: 55,
                                          height: 22,
                                          borderRadius: 6,
                                        ),
                                      )
                                    else
                                      Text(
                                        '${stats.attendancePercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 22 * fontScale,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kehadiran',
                                      style: TextStyle(
                                        fontSize: 10.5 * fontScale,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
