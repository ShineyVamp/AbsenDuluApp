import 'package:absendulu/core/constants/app_colors.dart';
import 'package:absendulu/core/services/storage_service.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';
import 'package:absendulu/extensions/navigation.dart';
import 'package:absendulu/presentation/screens/auth/login_screen.dart';
import 'package:absendulu/presentation/screens/main/main_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final token = StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      context.pushReplacement(const MainScreen());
    } else {
      context.pushReplacement(const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(14),
              decoration: NeumorphicDecorations.extruded(
                isDark: isDark,
                borderRadius: 28,
              ),
              child: Image.asset('assets/icons/icon.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              'AbsenDulu',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textHighDark : AppColors.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aplikasi Presensi Pelatihan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textMediumDark : AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
