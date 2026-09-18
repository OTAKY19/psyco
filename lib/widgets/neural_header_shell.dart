import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';

class NeuralHeaderShell extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool showLeftRing;
  final bool showRightRing;

  const NeuralHeaderShell({
    super.key,
    required this.child,
    this.height = 220,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.xxxl,
      AppSpacing.pageHorizontal,
      AppSpacing.xxl,
    ),
    this.showLeftRing = true,
    this.showRightRing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            if (showRightRing)
              Positioned(
                top: -height * 0.25,
                right: -height * 0.15,
                child: _NeuralRing(
                  size: height * 0.9,
                  color: AppColors.textOnPrimary,
                ),
              ),
            if (showLeftRing)
              Positioned(
                bottom: -height * 0.3,
                left: -height * 0.2,
                child: _NeuralRing(
                  size: height * 0.75,
                  color: AppColors.textOnPrimary,
                ),
              ),
            Positioned.fill(child: Padding(padding: padding, child: child)),
          ],
        ),
      ),
    );
  }
}

class _NeuralRing extends StatelessWidget {
  final double size;
  final Color color;

  const _NeuralRing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(color: color),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;

  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [size.width * 0.45, size.width * 0.32, size.width * 0.18];

    for (final r in radii) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, r, paint);
    }

    final dotPaint = Paint()..color = color.withValues(alpha: 0.12);
    const angle = 2 * math.pi * 0.3;
    for (final r in radii) {
      canvas.drawCircle(
        Offset(center.dx + r * math.cos(angle),
            center.dy + r * math.sin(angle)),
        3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.color != color;
}
