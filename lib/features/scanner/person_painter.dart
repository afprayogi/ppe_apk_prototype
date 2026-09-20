import 'package:flutter/material.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/domain/ppe_item.dart';

/// Normalised (0–1) bounding boxes of each PPE item on the demo figure.
const Map<PpeItem, List<Rect>> ppeBoxes = {
  PpeItem.helmet: [Rect.fromLTWH(0.35, 0.05, 0.30, 0.12)],
  PpeItem.goggles: [Rect.fromLTWH(0.38, 0.185, 0.24, 0.055)],
  PpeItem.mask: [Rect.fromLTWH(0.40, 0.245, 0.20, 0.055)],
  PpeItem.vest: [Rect.fromLTWH(0.29, 0.34, 0.42, 0.27)],
  PpeItem.gloves: [
    Rect.fromLTWH(0.10, 0.60, 0.13, 0.085),
    Rect.fromLTWH(0.77, 0.60, 0.13, 0.085),
  ],
  PpeItem.boots: [
    Rect.fromLTWH(0.27, 0.87, 0.19, 0.085),
    Rect.fromLTWH(0.54, 0.87, 0.19, 0.085),
  ],
};

/// A stylised worker figure with optional detection boxes on top.
class PersonPainter extends CustomPainter {
  const PersonPainter({
    required this.figure,
    this.boxes = const {},
    this.labelStyle,
  });

  final Color figure;

  /// Items to draw a box for → whether they were detected.
  final Map<PpeItem, bool> boxes;
  final TextStyle? labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);

    final fill = Paint()..color = figure;
    final limb = Paint()
      ..color = figure
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.075;

    canvas
      ..drawCircle(p(0.5, 0.2), size.width * 0.085, fill)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0.32 * size.width,
            0.31 * size.height,
            0.36 * size.width,
            0.32 * size.height,
          ),
          Radius.circular(size.width * 0.08),
        ),
        fill,
      )
      ..drawLine(p(0.30, 0.36), p(0.17, 0.60), limb)
      ..drawLine(p(0.70, 0.36), p(0.83, 0.60), limb)
      ..drawLine(p(0.42, 0.62), p(0.365, 0.88), limb)
      ..drawLine(p(0.58, 0.62), p(0.635, 0.88), limb);

    for (final entry in boxes.entries) {
      final color = entry.value ? AppColors.success : AppColors.danger;
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      final bg = Paint()..color = color.withValues(alpha: 0.16);
      final rects = ppeBoxes[entry.key]!;
      for (final r in rects) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left * size.width,
            r.top * size.height,
            r.width * size.width,
            r.height * size.height,
          ),
          const Radius.circular(8),
        );
        canvas
          ..drawRRect(rect, bg)
          ..drawRRect(rect, stroke);
      }
      // One label per item, above its first box.
      final first = rects.first;
      final tp = TextPainter(
        text: TextSpan(
          text: ' ${entry.key.label} ',
          style: (labelStyle ?? const TextStyle(fontSize: 10)).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            backgroundColor: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (first.left * size.width).clamp(0, size.width - tp.width);
      final dy = first.top * size.height - tp.height - 2;
      tp.paint(canvas, Offset(dx.toDouble(), dy < 0 ? 0 : dy));
    }
  }

  @override
  bool shouldRepaint(PersonPainter old) =>
      old.figure != figure || old.boxes != boxes;
}
