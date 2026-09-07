import 'package:absendulu/presentation/providers/auth_provider.dart';
import 'package:absendulu/presentation/providers/history_provider.dart';
import 'package:absendulu/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:absendulu/presentation/screens/history/history_screen.dart';
import 'package:absendulu/presentation/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchProfile();
      Provider.of<HistoryProvider>(context, listen: false).refreshHistory();
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final unselectedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF334155);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Provider.of<HistoryProvider>(
              context,
              listen: false,
            ).refreshHistory();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : unselectedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Center(
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 18,
                      right: 18,
                      bottom: 12,
                    ),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2230) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.35)
                              : const Color(0xFF64748B).withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final itemWidth = totalWidth / 3;

                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              left: _currentIndex * itemWidth,
                              top: 2,
                              bottom: 2,
                              width: itemWidth,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C54D8),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2C54D8,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildNavItem(
                                  0,
                                  Icons.home_outlined,
                                  'Beranda',
                                  isDark,
                                ),
                                _buildNavItem(
                                  1,
                                  Icons.history_rounded,
                                  'Riwayat',
                                  isDark,
                                ),
                                _buildNavItem(
                                  2,
                                  Icons.person_outline_rounded,
                                  'Profil',
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
