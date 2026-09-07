import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/services/location_service.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/presentation/providers/attendance_provider.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/providers/theme_provider.dart';
import 'package:absendulu/presentation/widgets/custom_snackbar.dart';
import 'package:absendulu/presentation/widgets/neumorphic_button.dart';
import 'package:absendulu/presentation/widgets/neumorphic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class GpsVerificationScreen extends StatefulWidget {
  final bool isCheckIn;

  const GpsVerificationScreen({super.key, required this.isCheckIn});

  @override
  State<GpsVerificationScreen> createState() => _GpsVerificationScreenState();
}

class _GpsVerificationScreenState extends State<GpsVerificationScreen> {
  GoogleMapController? _googleMapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).updateLocation();
    });
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmAttendance() async {
    final attendance = Provider.of<AttendanceProvider>(context, listen: false);

    if (!attendance.isInsideGeofence) {
      CustomSnackBar.showError(
        context,
        'Presensi ditolak: Anda berada di luar radius 300m dari Kampus PPKD Jakarta Pusat',
      );
      return;
    }

    final today = attendance.todayAttendance;
    final hasCheckedIn = today != null && today.isCheckedIn;
    final hasCheckedOut = today != null && today.isCheckedOut;
    final isAlreadyAttended = widget.isCheckIn ? hasCheckedIn : hasCheckedOut;

    if (isAlreadyAttended) {
      CustomSnackBar.showWarning(context, 'Anda sudah absen');
      return;
    }

    bool success;
    if (widget.isCheckIn) {
      success = await attendance.checkIn();
    } else {
      success = await attendance.checkOut();
    }

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        widget.isCheckIn ? 'Absen Masuk Berhasil!' : 'Absen Pulang Berhasil!',
      );
      context.pop();
    } else {
      CustomSnackBar.showError(
        context,
        attendance.errorMessage ?? 'Gagal memproses presensi',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attendance = Provider.of<AttendanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    final userName = auth.user?.name ?? 'Siswa PPKD';
    final today = attendance.todayAttendance;
    final isIzin = today != null && today.isIzin;
    final hasCheckedIn = today != null && today.isCheckedIn;
    final hasCheckedOut = today != null && today.isCheckedOut;
    final isLate =
        attendance.currentTime.hour > 8 ||
        (attendance.currentTime.hour == 8 &&
            (attendance.currentTime.minute > 0 ||
                attendance.currentTime.second > 0));

    final isAlreadyAttended = widget.isCheckIn ? hasCheckedIn : hasCheckedOut;

    final bool checkInWasLate = today?.isLate ?? false;

    String statusTag;
    Color statusColor;

    if (isIzin) {
      statusTag = 'IZIN';
      statusColor = AppColors.warning;
    } else if (hasCheckedOut) {
      statusTag = 'SUDAH PULANG';
      statusColor = const Color(0xFF10B981);
    } else if (hasCheckedIn) {
      if (checkInWasLate) {
        statusTag = 'TERLAMBAT';
        statusColor = const Color(0xFFEA580C);
      } else {
        statusTag = 'SUDAH CHECK IN';
        statusColor = AppColors.success;
      }
    } else {
      if (isLate) {
        statusTag = 'TERLAMBAT';
        statusColor = const Color(0xFFEA580C);
      } else {
        statusTag = 'BELUM CHECK IN';
        statusColor = isDark
            ? AppColors.textMediumDark
            : const Color(0xFF64748B);
      }
    }

    final currentPos = attendance.currentPosition;
    final lat = currentPos?.latitude ?? LocationService.ppkdLat;
    final lng = currentPos?.longitude ?? LocationService.ppkdLng;
    final userLatLng = LatLng(lat, lng);
    final ppkdLatLng = const LatLng(
      LocationService.ppkdLat,
      LocationService.ppkdLng,
    );
    final isSafe = attendance.isInsideGeofence;
    final distanceMeters = attendance.distanceToPpkd.toStringAsFixed(0);

    bool isButtonEnabled = false;
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    if (isIzin) {
      isButtonEnabled = false;
      buttonText = 'Anda Sedang Izin Hari Ini';
      buttonIcon = Icons.info_outline_rounded;
      buttonColor = const Color(0xFF94A3B8);
    } else if (isAlreadyAttended) {
      isButtonEnabled = false;
      buttonText = 'Anda sudah absen';
      buttonIcon = Icons.check_circle_rounded;
      buttonColor = const Color(0xFF94A3B8);
    } else if (!isSafe) {
      isButtonEnabled = false;
      buttonText = 'Di Luar Radius Presensi (Maks 300m)';
      buttonIcon = Icons.block_rounded;
      buttonColor = const Color(0xFF94A3B8);
    } else {
      isButtonEnabled = true;
      buttonText = widget.isCheckIn
          ? 'Konfirmasi Absen'
          : 'Konfirmasi Absen Pulang';
      buttonIcon = widget.isCheckIn ? Icons.check : Icons.logout_rounded;
      buttonColor = widget.isCheckIn
          ? const Color(0xFF2C54D8)
          : const Color(0xFF10B981);
    }

    final shortDay = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ][DateTime.now().weekday - 1];
    final shortMonth = [
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
    ][DateTime.now().month - 1];
    final dateStr = '$shortDay, ${DateTime.now().day} $shortMonth';
    final timeStr =
        '${DateFormatter.formatTime(attendance.currentTime, isRoman: theme.isRomanClock)} WIB';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.wait([
                attendance.updateLocation(),
                attendance.loadTodayAttendance(),
              ]);
              final currentPos = attendance.currentPosition;
              if (currentPos != null && _googleMapController != null) {
                _googleMapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(currentPos.latitude, currentPos.longitude),
                      zoom: 17.5,
                    ),
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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
                              'Verifikasi Lokasi',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? AppColors.textHighDark
                                    : AppColors.textHigh,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  NeumorphicCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 24,
                    child: SizedBox(
                      height: 270,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: userLatLng,
                                zoom: 17.0,
                              ),
                              onMapCreated: (controller) {
                                _googleMapController = controller;
                              },
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                              scrollGesturesEnabled: true,
                              zoomGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: false,
                              circles: {
                                Circle(
                                  circleId: const CircleId('geofence_ppkd'),
                                  center: ppkdLatLng,
                                  radius: LocationService.geofenceRadius,
                                  fillColor: const Color(
                                    0xFF2C54D8,
                                  ).withValues(alpha: 0.12),
                                  strokeColor: const Color(0xFF2C54D8),
                                  strokeWidth: 2,
                                ),
                              },
                              markers: {
                                Marker(
                                  markerId: const MarkerId('marker_ppkd'),
                                  position: ppkdLatLng,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueAzure,
                                  ),
                                  infoWindow: const InfoWindow(
                                    title: 'PPKD Jakarta Pusat',
                                    snippet: 'Radius Presensi 300m',
                                  ),
                                ),
                                Marker(
                                  markerId: const MarkerId('marker_user'),
                                  position: userLatLng,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen,
                                  ),
                                  infoWindow: const InfoWindow(
                                    title: 'Posisi Anda',
                                  ),
                                ),
                              },
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardBgDark.withValues(
                                          alpha: 0.92,
                                        )
                                      : Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 3.5,
                                      backgroundColor: Color(0xFF2C54D8),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Radius Presensi 300m',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      _googleMapController?.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: userLatLng,
                                            zoom: 17.5,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.cardBgDark
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.my_location_rounded,
                                        size: 18,
                                        color: Color(0xFF2C54D8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      attendance.updateLocation();
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.cardBgDark
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                        color: Color(0xFF2C54D8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.cardBgDark
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            _googleMapController?.animateCamera(
                                              CameraUpdate.zoomIn(),
                                            );
                                          },
                                          child: const SizedBox(
                                            width: 36,
                                            height: 34,
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 20,
                                              color: Color(0xFF2C54D8),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 1,
                                          width: 20,
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.black12,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            _googleMapController?.animateCamera(
                                              CameraUpdate.zoomOut(),
                                            );
                                          },
                                          child: const SizedBox(
                                            width: 36,
                                            height: 34,
                                            child: Icon(
                                              Icons.remove_rounded,
                                              size: 20,
                                              color: Color(0xFF2C54D8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardBgDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSafe
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: isSafe
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isSafe
                                                ? 'Dalam Radius Aman PPKD'
                                                : (attendance.errorMessage !=
                                                          null
                                                      ? 'Kendala Lokasi'
                                                      : 'Di Luar Radius Aman PPKD'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.textHighDark
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isSafe
                                                ? 'Jarak aktual: $distanceMeters Meter dari titik gerbang'
                                                : (attendance.errorMessage !=
                                                          null
                                                      ? attendance.errorMessage!
                                                      : 'Jarak aktual: $distanceMeters Meter (Maksimal 300m)'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.textMediumDark
                                                  : const Color(0xFF64748B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        isSafe
                                            ? 'AMAN'
                                            : (attendance.errorMessage != null
                                                  ? 'ERROR'
                                                  : 'DILUAR'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isSafe
                                              ? const Color(0xFF047857)
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeumorphicCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presensi Hari Ini, $userName',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textHighDark
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusTag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textMediumDark
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppColors.textHighDark
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check In: ${DateFormatter.formatTimeString(today?.effectiveCheckInTime ?? '-', isRoman: theme.isRomanClock)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMediumDark
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (hasCheckedOut) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Check Out: ${DateFormatter.formatTimeString(today.effectiveCheckOutTime, isRoman: theme.isRomanClock)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textMediumDark
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          currentPos != null
                              ? 'Koordinat lokasi: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
                              : 'Koordinat lokasi belum tersedia',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMediumDark
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          attendance.errorMessage != null && !isSafe
                              ? attendance.errorMessage!
                              : (currentPos == null
                                    ? 'Gagal mendapatkan lokasi'
                                    : (isSafe
                                          ? 'Lokasi terverifikasi di PPKD Jakarta Pusat ($distanceMeters m)'
                                          : 'Di luar radius presensi ($distanceMeters m dari PPKD)')),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: currentPos == null || !isSafe
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF059669),
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.my_location_rounded,
                              size: 16,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Radius absensi 300m dari PPKD Jakarta Pusat. Pastikan GPS aktif dan titik lokasi stabil sebelum check-in.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textMediumDark
                                      : const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (attendance.errorMessage != null && !isSafe) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: NeumorphicDecorations.extruded(
                        isDark: isDark,
                        borderRadius: 20,
                        color: isDark
                            ? const Color(0xFF1B2230)
                            : const Color(0xFFEEF2F7),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kendala Verifikasi Presensi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  attendance.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textMediumDark
                                        : const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  NeumorphicButton(
                    isPrimary: true,
                    color: buttonColor,
                    isLoading: attendance.isLoading,
                    onPressed: isButtonEnabled
                        ? _handleConfirmAttendance
                        : () {
                            if (isAlreadyAttended) {
                              CustomSnackBar.showWarning(
                                context,
                                'Anda sudah absen',
                              );
                            } else if (isIzin) {
                              CustomSnackBar.showWarning(
                                context,
                                'Anda sedang izin hari ini',
                              );
                            } else {
                              CustomSnackBar.showError(
                                context,
                                attendance.errorMessage ??
                                    'Presensi ditolak: Anda berada di luar radius 300m dari Kampus PPKD Jakarta Pusat',
                              );
                            }
                          },
                    height: 54,
                    borderRadius: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeumorphicButton(
                    onPressed: () => attendance.updateLocation(),
                    height: 48,
                    borderRadius: 24,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Kalibrasi GPS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
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
