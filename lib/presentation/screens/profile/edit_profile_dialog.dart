import 'dart:convert';
import 'package:absendulu/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/core/utils/image_helper.dart';
import 'package:absendulu/data/models/batch_model.dart';
import 'package:absendulu/data/models/training_model.dart';
import 'package:absendulu/data/repositories/master_repository.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/widgets/custom_snackbar.dart';
import 'package:absendulu/presentation/widgets/neumorphic_button.dart';
import 'package:absendulu/presentation/widgets/neumorphic_text_field.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final MasterRepository _masterRepo = MasterRepository();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  String _gender = 'L';
  dynamic _selectedBatchId;
  dynamic _selectedTrainingId;
  List<BatchModel> _batches = [];
  List<TrainingModel> _trainings = [];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _gender = (user?.jenisKelamin == 'P') ? 'P' : 'L';
    _selectedBatchId = user?.batchId;
    _selectedTrainingId = user?.trainingId;
    _loadMasterData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    try {
      final batches = await _masterRepo.getBatches();
      final trainings = await _masterRepo.getTrainings();
      if (mounted) {
        setState(() {
          _batches = batches;
          _trainings = trainings;
        });
      }
    } catch (_) {}
  }

  String _getBatchName(UserModel? user) {
    if (user?.batchKe != null && user!.batchKe.toString().isNotEmpty) {
      return 'Batch ${user.batchKe}';
    }
    if (_selectedBatchId == null) return '-';
    if (_batches.isNotEmpty) {
      try {
        final found = _batches.firstWhere(
          (b) => b.id.toString() == _selectedBatchId.toString(),
        );
        return found.displayName;
      } catch (_) {}
    }
    return 'Batch #$_selectedBatchId';
  }

  String _getTrainingTitle(UserModel? user) {
    if (user?.trainingTitle != null && user!.trainingTitle!.isNotEmpty) {
      return user.trainingTitle!;
    }
    if (_selectedTrainingId == null) return '-';
    if (_trainings.isNotEmpty) {
      try {
        final found = _trainings.firstWhere(
          (t) => t.id.toString() == _selectedTrainingId.toString(),
        );
        return found.title;
      } catch (_) {}
    }
    return 'Kejuruan #$_selectedTrainingId';
  }

  Future<void> _showPhotoSourceSheet() async {
    FocusScope.of(context).unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppColors.cardBgDark : AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Sumber Foto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textHighDark : AppColors.textHigh,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Ambil dari Kamera',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textHighDark : AppColors.textHigh,
                  ),
                ),
                onTap: () => bCtx.pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textHighDark : AppColors.textHigh,
                  ),
                ),
                onTap: () => bCtx.pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null && mounted) {
      await _pickAndUploadPhoto(source);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    FocusScope.of(context).unfocus();
    final base64String = await ImageHelper.pickImageAsBase64(source: source);
    if (base64String != null && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.updateProfilePhoto(base64String);
      if (mounted) {
        if (success) {
          CustomSnackBar.showSuccess(
            context,
            'Foto profil berhasil diperbarui',
          );
        } else {
          CustomSnackBar.showError(
            context,
            auth.errorMessage ?? 'Gagal memperbarui foto profil',
          );
        }
      }
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      CustomSnackBar.showError(context, 'Nama lengkap tidak boleh kosong');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile(
      name: name,
      email: _emailController.text.trim(),
      jenisKelamin: _gender,
      batchId: _selectedBatchId,
      trainingId: _selectedTrainingId,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(context, 'Profil berhasil diperbarui');
      context.pop();
    } else {
      CustomSnackBar.showError(
        context,
        auth.errorMessage ?? 'Gagal memperbarui profil',
      );
    }
  }

  Widget _buildAvatarImage(String? photo, String? photoUrl, String? name) {
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return Image.network(
        photoUrl.trim(),
        fit: BoxFit.cover,
        width: 72,
        height: 72,
        errorBuilder: (context, error, stackTrace) =>
            _buildAvatarFallback(name),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
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
          width: 72,
          height: 72,
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
      width: 72,
      height: 72,
      errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(name),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLockedField({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMediumDark : AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: NeumorphicDecorations.insetWell(
            isDark: isDark,
            borderRadius: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.textLowDark : AppColors.textLow,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textMediumDark
                        : AppColors.textMedium,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: isDark ? AppColors.textLowDark : AppColors.textLow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Dialog(
      backgroundColor: isDark ? AppColors.cardBgDark : AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ubah Profil Siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textHighDark
                            : AppColors.textHigh,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: NeumorphicDecorations.extruded(
                      isDark: isDark,
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: auth.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : _buildAvatarImage(
                              auth.user?.profilePhoto,
                              auth.user?.profilePhotoUrl,
                              auth.user?.name,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphicButton(
                  onPressed: _showPhotoSourceSheet,
                  height: 44,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ganti Foto Profil',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NeumorphicTextField(
                  controller: _nameController,
                  labelText: 'Nama Lengkap',
                  hintText: 'Nama lengkap Anda',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data di bawah ini dikunci oleh sistem pelatihan PPKD. Hubungi Admin jika terdapat perubahan data.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: isDark
                                ? AppColors.textMediumDark
                                : AppColors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphicTextField(
                  controller: _emailController,
                  labelText: 'Email Akun',
                  hintText: 'nama@siswa.ppkd.id',
                  readOnly: true,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: isDark ? AppColors.textLowDark : AppColors.textLow,
                  ),
                  suffixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: isDark ? AppColors.textLowDark : AppColors.textLow,
                  ),
                ),
                const SizedBox(height: 14),
                _buildLockedField(
                  isDark: isDark,
                  label: 'Jenis Kelamin',
                  value: _gender == 'L' ? 'Laki-laki' : 'Perempuan',
                  icon: Icons.person_pin_circle_outlined,
                ),
                const SizedBox(height: 14),
                _buildLockedField(
                  isDark: isDark,
                  label: 'Batch Pelatihan',
                  value: _getBatchName(auth.user),
                  icon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 14),
                _buildLockedField(
                  isDark: isDark,
                  label: 'Kejuruan Pelatihan',
                  value: _getTrainingTitle(auth.user),
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 22),
                NeumorphicButton(
                  isPrimary: true,
                  isLoading: auth.isLoading,
                  onPressed: _handleSave,
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
