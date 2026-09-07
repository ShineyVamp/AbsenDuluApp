import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/widgets/custom_snackbar.dart';
import 'package:absendulu/presentation/widgets/neumorphic_button.dart';
import 'package:absendulu/presentation/widgets/neumorphic_text_field.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty) {
      CustomSnackBar.showError(context, 'Masukkan password lama Anda');
      return;
    }

    if (newPassword.isEmpty) {
      CustomSnackBar.showError(context, 'Masukkan password baru');
      return;
    }

    if (newPassword.length < 6) {
      CustomSnackBar.showError(context, 'Password baru minimal 6 karakter');
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackBar.showError(context, 'Konfirmasi password baru tidak cocok');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.user?.email ?? '';

    if (email.isEmpty) {
      CustomSnackBar.showError(context, 'Email akun tidak ditemukan');
      return;
    }

    final success = await auth.changePassword(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(context, 'Password berhasil diperbarui');
      context.pop();
    } else {
      CustomSnackBar.showError(
        context,
        auth.errorMessage ?? 'Gagal memperbarui password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Dialog(
      backgroundColor: isDark ? AppColors.cardBgDark : AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ganti Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textHighDark
                              : AppColors.textHigh,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Perbarui kata sandi akun Anda secara berkala demi keamanan akun.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.textMediumDark
                      : AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              NeumorphicTextField(
                controller: _oldPasswordController,
                labelText: 'Password Lama',
                hintText: '••••••••',
                obscureText: _obscureOldPassword,
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOldPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.textLowDark
                        : AppColors.textLow,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              NeumorphicTextField(
                controller: _newPasswordController,
                labelText: 'Password Baru',
                hintText: 'Minimal 6 karakter',
                obscureText: _obscureNewPassword,
                prefixIcon: const Icon(
                  Icons.vpn_key_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.textLowDark
                        : AppColors.textLow,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              NeumorphicTextField(
                controller: _confirmPasswordController,
                labelText: 'Konfirmasi Password Baru',
                hintText: 'Ulangi password baru',
                obscureText: _obscureConfirmPassword,
                prefixIcon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: isDark
                        ? AppColors.textLowDark
                        : AppColors.textLow,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 22),
              NeumorphicButton(
                isPrimary: true,
                isLoading: auth.isLoading,
                onPressed: _handleSubmit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Password Baru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
