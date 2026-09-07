import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/widgets/custom_snackbar.dart';
import 'package:absendulu/presentation/widgets/neumorphic_button.dart';
import 'package:absendulu/presentation/widgets/neumorphic_text_field.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomSnackBar.showError(context, 'Masukkan email terdaftar');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.requestForgotPassword(email);
    if (!mounted) return;

    if (success) {
      CustomSnackBar.showSuccess(
        context,
        isResend
            ? 'Kode OTP baru telah dikirim ke email'
            : 'Kode OTP telah dikirim ke email',
      );
      if (!_otpSent) {
        setState(() => _otpSent = true);
      }
    } else {
      CustomSnackBar.showError(
        context,
        auth.errorMessage ?? 'Gagal mengirim OTP',
      );
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();

    if (otp.isEmpty || newPass.isEmpty) {
      CustomSnackBar.showError(context, 'Lengkapi kode OTP dan password baru');
      return;
    }

    if (newPass.length < 6) {
      CustomSnackBar.showError(context, 'Password baru minimal 6 karakter');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPass,
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
                      if (_otpSent) ...[
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _otpSent = false),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _otpSent ? 'Verifikasi OTP' : 'Lupa Password',
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
              const SizedBox(height: 16),
              if (!_otpSent) ...[
                Text(
                  'Masukkan email akun yang terdaftar untuk menerima kode verifikasi OTP.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.textMediumDark
                        : AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphicTextField(
                  controller: _emailController,
                  labelText: 'Email Akun Siswa',
                  hintText: 'email@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                NeumorphicButton(
                  isPrimary: true,
                  isLoading: auth.isLoading,
                  onPressed: () => _handleSendOtp(isResend: false),
                  child: const Text(
                    'Kirim Kode OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'OTP dikirim ke: ${_emailController.text.trim()}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textHighDark
                                : AppColors.textHigh,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _otpSent = false),
                        child: const Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphicTextField(
                  controller: _otpController,
                  labelText: 'Kode OTP (6 Digit)',
                  hintText: 'Masukkan kode OTP',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.pin_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                NeumorphicTextField(
                  controller: _newPasswordController,
                  labelText: 'Password Baru',
                  hintText: 'Minimal 6 karakter',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => _handleSendOtp(isResend: true),
                    child: const Text(
                      'Kirim Ulang OTP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                NeumorphicButton(
                  isPrimary: true,
                  isLoading: auth.isLoading,
                  onPressed: _handleResetPassword,
                  child: const Text(
                    'Simpan Password Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

