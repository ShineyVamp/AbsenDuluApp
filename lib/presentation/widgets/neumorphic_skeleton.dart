import 'package:flutter/material.dart';
import 'package:absendulu/core/theme/neumorphic_decorations.dart';

class NeumorphicSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const NeumorphicSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const NeumorphicSkeleton.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  State<NeumorphicSkeleton> createState() => _NeumorphicSkeletonState();
}

class _NeumorphicSkeletonState extends State<NeumorphicSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor =
        isDark ? const Color(0xFF1E2838) : const Color(0xFFDDE6F2);
    final highlightColor =
        isDark ? const Color(0xFF2C3B52) : const Color(0xFFF3F7FC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.35).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.35).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HistoryCardSkeleton extends StatelessWidget {
  const HistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NeumorphicDecorations.extruded(
        isDark: isDark,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              NeumorphicSkeleton(width: 120, height: 16, borderRadius: 6),
              NeumorphicSkeleton(width: 60, height: 22, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: Row(
                  children: [
                    NeumorphicSkeleton.circle(size: 14),
                    SizedBox(width: 6),
                    NeumorphicSkeleton(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    NeumorphicSkeleton.circle(size: 14),
                    SizedBox(width: 6),
                    NeumorphicSkeleton(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              NeumorphicSkeleton.circle(size: 12),
              SizedBox(width: 6),
              NeumorphicSkeleton(width: 160, height: 10, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const HistoryListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const HistoryCardSkeleton(),
      ),
    );
  }
}

class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: List.generate(2, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicDecorations.extrudedSm(
              isDark: isDark,
              borderRadius: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                NeumorphicSkeleton.circle(size: 28),
                SizedBox(height: 12),
                NeumorphicSkeleton(width: 50, height: 22, borderRadius: 6),
                SizedBox(height: 6),
                NeumorphicSkeleton(width: 70, height: 12, borderRadius: 4),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class RegisterFormSkeleton extends StatelessWidget {
  const RegisterFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 170, height: 22, borderRadius: 6),
          ),
          SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 280, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 135, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 50, borderRadius: 14),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 125, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 50, borderRadius: 14),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 90, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NeumorphicSkeleton(height: 44, borderRadius: 14),
              ),
              SizedBox(width: 12),
              Expanded(
                child: NeumorphicSkeleton(height: 44, borderRadius: 14),
              ),
            ],
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 105, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 48, borderRadius: 14),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 120, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 48, borderRadius: 14),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 75, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 50, borderRadius: 14),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: NeumorphicSkeleton(width: 145, height: 14, borderRadius: 4),
          ),
          SizedBox(height: 8),
          NeumorphicSkeleton(height: 50, borderRadius: 14),
          SizedBox(height: 16),
          Row(
            children: [
              NeumorphicSkeleton(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 12),
              Expanded(
                child: NeumorphicSkeleton(height: 14, borderRadius: 4),
              ),
            ],
          ),
          SizedBox(height: 24),
          NeumorphicSkeleton(height: 52, borderRadius: 16),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: NeumorphicDecorations.extruded(
                isDark: isDark,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: NeumorphicSkeleton.circle(size: 84),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: NeumorphicSkeleton(width: 140, height: 20, borderRadius: 6),
          ),
          const SizedBox(height: 6),
          const Center(
            child: NeumorphicSkeleton(width: 180, height: 14, borderRadius: 4),
          ),
          const SizedBox(height: 24),
          const NeumorphicSkeleton(width: 100, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicDecorations.extruded(
              isDark: isDark,
              borderRadius: 16,
            ),
            child: Column(
              children: const [
                NeumorphicSkeleton(height: 20, borderRadius: 6),
                SizedBox(height: 14),
                NeumorphicSkeleton(height: 20, borderRadius: 6),
                SizedBox(height: 14),
                NeumorphicSkeleton(height: 20, borderRadius: 6),
                SizedBox(height: 14),
                NeumorphicSkeleton(height: 20, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NeumorphicSkeleton(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicDecorations.extruded(
              isDark: isDark,
              borderRadius: 16,
            ),
            child: Column(
              children: const [
                NeumorphicSkeleton(height: 20, borderRadius: 6),
                SizedBox(height: 14),
                NeumorphicSkeleton(height: 20, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const NeumorphicSkeleton(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicDecorations.extruded(
              isDark: isDark,
              borderRadius: 16,
            ),
            child: Column(
              children: const [
                NeumorphicSkeleton(height: 20, borderRadius: 6),
                SizedBox(height: 14),
                NeumorphicSkeleton(height: 20, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
