import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/core/utils/date_formatter.dart';
import 'package:absendulu/data/models/batch_model.dart';
import 'package:absendulu/data/models/training_model.dart';
import 'package:absendulu/data/repositories/master_repository.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/screens/auth/login_screen.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/providers/theme_provider.dart';
import 'package:absendulu/presentation/widgets/neumorphic_button.dart';
import 'package:absendulu/presentation/widgets/neumorphic_card.dart';
import 'package:absendulu/presentation/widgets/neumorphic_skeleton.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/data/models/user_model.dart';
import 'package:absendulu/presentation/screens/profile/edit_profile_dialog.dart';
import 'package:absendulu/presentation/screens/profile/change_password_dialog.dart';
import 'package:absendulu/presentation/screens/auth/forgot_password_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MasterRepository _masterRepo = MasterRepository();
  List<BatchModel> _batches = [];
  List<TrainingModel> _trainings = [];
  bool _isLoading = true;

  bool _reminderInEnabled = true;
  bool _reminderOutEnabled = true;
  String _reminderInTime = '07:45';
  String _reminderOutTime = '15:00';

  @override
  void initState() {
    super.initState();
    _reminderInEnabled = StorageService.getReminderCheckIn();
    _reminderOutEnabled = StorageService.getReminderCheckOut();
    _reminderInTime = StorageService.getReminderCheckInTime();
    _reminderOutTime = StorageService.getReminderCheckOutTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _pickReminderTime({required bool isCheckIn}) async {
    final currentTimeStr = isCheckIn ? _reminderInTime : _reminderOutTime;
    final parts = currentTimeStr.split(':');
    final initialHour = int.tryParse(parts[0]) ?? (isCheckIn ? 7 : 15);
    final initialMinute = parts.length > 1
        ? (int.tryParse(parts[1]) ?? (isCheckIn ? 45 : 0))
        : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isCheckIn) {
          _reminderInTime = formatted;
          StorageService.setReminderCheckInTime(formatted);
        } else {
          _reminderOutTime = formatted;
          StorageService.setReminderCheckOutTime(formatted);
        }
      });
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await Future.wait([
        auth.fetchProfile(),
        _fetchMasterData(),
      ]);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchMasterData() async {
    try {
      final batches = await _masterRepo.getBatches();
      final trainings = await _masterRepo.getTrainings();
      if (mounted) {
        _batches = batches;
        _trainings = trainings;
      }
    } catch (_) {}
  }

  String _getTrainingName(dynamic trainingId, UserModel? user) {
    if (user?.trainingTitle != null && user!.trainingTitle!.isNotEmpty) {
      return user.trainingTitle!;
    }
    if (trainingId == null && user != null) {
      trainingId = user.trainingId;
    }
    if (trainingId == null) return '-';
    try {
      final found = _trainings.firstWhere(
        (t) => t.id.toString() == trainingId.toString(),
      );
      return found.title;
    } catch (_) {
      return 'Kejuruan #$trainingId';
    }
  }

  String _getBatchName(dynamic batchId, UserModel? user) {
    if (user?.batchKe != null && user!.batchKe.toString().isNotEmpty) {
      return 'Batch ${user.batchKe}';
    }
    if (batchId == null && user != null) {
      batchId = user.batchId;
    }
    if (batchId == null) return '-';
    try {
      final found = _batches.firstWhere(
        (b) => b.id.toString() == batchId.toString(),
      );
      return found.displayName;
    } catch (_) {
      return 'Batch #$batchId';
    }
  }

  String _formatJoinDate(String? rawDate, UserModel? user) {
    if (rawDate == null || rawDate.isEmpty) {
      return '-';
    }
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormatter.formatIndonesianDate(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildAvatarImage(String? photo, String? photoUrl, String? name) {
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return Image.network(
        photoUrl.trim(),
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(name),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (photo == null || photo.trim().isEmpty) {
      return _buildAvatarFallback(name);
    }

    final trimmed = photo.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final base64String = trimmed.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 96,
          height: 96,
          errorBuilder: (_, _, _) => _buildAvatarFallback(name),
        );
      } catch (_) {
        return _buildAvatarFallback(name);
      }
    }

    const domain = 'https://appabsensi.mobileprojp.com';
    String finalUrl = trimmed;

    if (finalUrl.startsWith('http://localhost') ||
        finalUrl.startsWith('http://127.0.0.1')) {
      finalUrl = finalUrl
          .replaceFirst('http://localhost:8000', domain)
          .replaceFirst('http://127.0.0.1:8000', domain)
          .replaceFirst('http://localhost', domain)
          .replaceFirst('http://127.0.0.1', domain);
    } else if (finalUrl.startsWith('http://appabsensi.mobileprojp.com')) {
      finalUrl = finalUrl.replaceFirst('http://', 'https://');
    }

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      final clean = finalUrl.startsWith('/') ? finalUrl.substring(1) : finalUrl;
      finalUrl = '$domain/public/$clean';
    }

    return Image.network(
      finalUrl,
      fit: BoxFit.cover,
      width: 96,
      height: 96,
      errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(name),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(String? name) {
    final initials = (name != null && name.trim().isNotEmpty)
        ? name.trim().substring(0, 1).toUpperCase()
        : 'U';
    return Container(
      color: const Color(0xFFCBD5E0),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFF0F172A).withValues(alpha: 0.08),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMediumDark : AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (trailing != null)
          trailing
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textHighDark : AppColors.textHigh,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openEditDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const EditProfileDialog(),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const ProfileSkeleton()
            : RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: NeumorphicDecorations.extruded(
                              isDark: isDark,
                              shape: BoxShape.circle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(48),
                              child: _buildAvatarImage(
                                user?.profilePhoto,
                                user?.profilePhotoUrl,
                                user?.name,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _openEditDialog,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Nama Siswa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textHighDark
                            : AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'nama@siswa.ppkd.id',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMediumDark
                            : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data Pribadi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textHighDark
                                : AppColors.textHigh,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _openEditDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ubah Data',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeumorphicCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Nama Lengkap',
                            value: user?.name ?? '-',
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email Akun',
                            value: user?.email ?? '-',
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildInfoRow(
                            icon: Icons.wc_rounded,
                            label: 'Jenis Kelamin',
                            value: user?.jenisKelamin == 'P'
                                ? 'Perempuan'
                                : (user?.jenisKelamin == 'L'
                                      ? 'Laki-laki'
                                      : '-'),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildInfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Tanggal Terdaftar',
                            value: _formatJoinDate(user?.createdAt, user),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data Pelatihan PPKD',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textHighDark
                                : AppColors.textHigh,
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _openEditDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ubah Pelatihan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeumorphicCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.school_outlined,
                            label: 'Kejuruan Pelatihan',
                            value: _getTrainingName(user?.trainingId, user),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildInfoRow(
                            icon: Icons.groups_outlined,
                            label: 'Batch / Angkatan',
                            value: _getBatchName(user?.batchId, user),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pengaturan Sistem',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textHighDark
                            : AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeumorphicCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    theme.isDarkMode
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Mode Tampilan Gelap',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textHighDark
                                          : AppColors.textHigh,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: theme.isDarkMode,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => theme.toggleTheme(val),
                              ),
                            ],
                          ),
                          _buildDivider(isDark),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Jam Angka Romawi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textHighDark
                                          : AppColors.textHigh,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: theme.isRomanClock,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => theme.toggleRomanClock(val),
                              ),
                            ],
                          ),
                          _buildDivider(isDark),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const ChangePasswordDialog(),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.vpn_key_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Ganti Password',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.textLowDark
                                        : AppColors.textLow,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildDivider(isDark),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => ForgotPasswordDialog(
                                  initialEmail: user?.email,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_reset_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Lupa Password',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.textLowDark
                                        : AppColors.textLow,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildDivider(isDark),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Versi Aplikasi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textMediumDark
                                            : AppColors.textMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '1.0.0',
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
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pengingat Presensi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textHighDark
                            : AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeumorphicCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengingat Masuk',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _pickReminderTime(isCheckIn: true),
                                        child: Text(
                                          'Waktu: ${DateFormatter.formatTimeString(_reminderInTime, isRoman: theme.isRomanClock)} WIB',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: _reminderInEnabled,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _reminderInEnabled = val);
                                  StorageService.setReminderCheckIn(val);
                                },
                              ),
                            ],
                          ),
                          _buildDivider(isDark),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm_on_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pengingat Pulang',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textHighDark
                                              : AppColors.textHigh,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _pickReminderTime(isCheckIn: false),
                                        child: Text(
                                          'Waktu: ${DateFormatter.formatTimeString(_reminderOutTime, isRoman: theme.isRomanClock)} WIB',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: _reminderOutEnabled,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _reminderOutEnabled = val);
                                  StorageService.setReminderCheckOut(val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    NeumorphicButton(
                      isPrimary: true,
                      color: AppColors.danger,
                      height: 50,
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: const Text('Keluar dari Akun?'),
                            content: const Text(
                              'Anda perlu masuk kembali dengan email dan password untuk mengakses aplikasi.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => dCtx.pop(false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                ),
                                onPressed: () => dCtx.pop(true),
                                child: const Text(
                                  'Keluar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          await auth.logout();
                          if (context.mounted) {
                            context.pushAndRemoveAll(const LoginScreen());
                          }
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluar Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
