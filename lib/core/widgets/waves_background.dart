import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';

/// Fond animé inspiré de VANTA.WAVES (Three.js) — grille de vagues 3D
/// simplifiée en CustomPainter pour Flutter.
class WavesBackground extends StatefulWidget {
  const WavesBackground({super.key, this.child});

  final Widget? child;

  @override
  State<WavesBackground> createState() => _WavesBackgroundState();
}

class _WavesBackgroundState extends State<WavesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            return CustomPaint(
              painter: _WavesPainter(time: _controller.value * 2 * math.pi),
              size: Size.infinite,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[GlassTokens.bgDeepAlt, GlassTokens.bgDeep],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    const int cols = 22;
    const int rows = 14;
    final double cellW = size.width / cols;
    final double cellH = size.height / rows * 0.55;
    final double originX = size.width * 0.05;
    final double originY = size.height * 0.42;

    final Paint linePaint = Paint()
      ..color = GlassTokens.waveColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint highlightPaint = Paint()
      ..color = GlassTokens.waveColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int row = 0; row <= rows; row++) {
      final Path path = Path();
      bool started = false;
      for (int col = 0; col <= cols; col++) {
        final double x = originX + col * cellW;
        final double z = row * cellH;
        final double wave = _waveHeight(col, row);
        final double y = originY + z * 0.55 - wave;

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        row % 3 == 0 ? highlightPaint : linePaint,
      );
    }

    for (int col = 0; col <= cols; col++) {
      final Path path = Path();
      bool started = false;
      for (int row = 0; row <= rows; row++) {
        final double x = originX + col * cellW;
        final double z = row * cellH;
        final double wave = _waveHeight(col, row);
        final double y = originY + z * 0.55 - wave;

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // Voile sombre pour lisibilité du contenu
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  double _waveHeight(int col, int row) {
    final double x = col * 0.35;
    final double z = row * 0.25;
    final double speed = time * 0.9;
    final double primary = math.sin(speed - x * 0.9 + z * 0.55);
    final double secondary = math.cos(speed * 0.7 + x * 0.4 - z * 0.3);
    return (primary + secondary) * 8 + 6;
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.time != time;
}

/// Applique le flou glassmorphism autour d'un enfant.
class GlassBlur extends StatelessWidget {
  const GlassBlur({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.fillColor,
    this.active = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? fillColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(GlassTokens.glassRadius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: active ? GlassTokens.activeGlowShadow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.glassBlurSigma,
            sigmaY: GlassTokens.glassBlurSigma,
          ),
          // BackdropFilter crée un LookupBoundary : un Material transparent est
          // nécessaire DANS le filtre pour que les widgets Material-dependent
          // (TextField, form, InkWell…) retrouvent un ancêtre Material.
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: fillColor ??
                    (active ? GlassTokens.activeFill : GlassTokens.glassFill),
                borderRadius: radius,
                border: Border.all(
                  color: borderColor ??
                      (active
                          ? GlassTokens.activeBorder
                          : GlassTokens.glassBorderStrong),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
