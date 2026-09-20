import 'package:flutter/material.dart';
import 'package:gearguard/core/theme/app_theme.dart';

/// The GearGuard mark: a safety shield with a check.
///
/// Geometry mirrors `assets/brand/logo.svg` (108-unit grid).
class GearLogo extends StatelessWidget {
  const GearLogo({this.size = 48, this.framed = true, super.key});

  final double size;

  /// Draw the gradient app-icon tile behind the shield.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'GearGuard logo',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(framed: framed),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.framed});

  final bool framed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 108);

    if (framed) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 108, 108),
            const Radius.circular(24.3),
          ),
          Paint()
            ..shader = AppColors.brandGradient.createShader(
              const Rect.fromLTWH(0, 0, 108, 108),
            ),
        )
        ..translate(54, 54)
        ..scale(1.25)
        ..translate(-54, -54);
    }

    final shield = Path()
      ..moveTo(54, 24)
      ..lineTo(79, 33)
      ..lineTo(79, 52)
      ..cubicTo(79, 68, 68, 77, 54, 84)
      ..cubicTo(40, 77, 29, 68, 29, 52)
      ..lineTo(29, 33)
      ..close();
    canvas
      ..drawPath(shield, Paint()..color = Colors.white)
      ..drawPath(
        Path()
          ..moveTo(41, 55)
          ..lineTo(50, 64)
          ..lineTo(67, 43),
        Paint()
          ..color = const Color(0xFFEA580C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.framed != framed;
}

class GearWordmark extends StatelessWidget {
  const GearWordmark({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GearLogo(size: size),
        SizedBox(width: size * 0.3),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Gear'),
              TextSpan(
                text: 'Guard',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}
