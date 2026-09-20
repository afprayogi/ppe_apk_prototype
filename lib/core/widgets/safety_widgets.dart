import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gearguard/core/theme/app_theme.dart';
import 'package:gearguard/core/utils/formatters.dart';
import 'package:gearguard/domain/employee.dart';
import 'package:gearguard/domain/ppe_item.dart';

/// Traffic-light colour for a 0–1 compliance value.
Color complianceColor(double? v) {
  if (v == null) return const Color(0xFF94A3B8);
  if (v >= 0.9) return AppColors.success;
  if (v >= 0.7) return AppColors.warning;
  return AppColors.danger;
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  factory StatusPill.compliance({required bool compliant, Key? key}) =>
      StatusPill(
        key: key,
        label: compliant ? 'Compliant' : 'Violation',
        color: compliant ? AppColors.success : AppColors.danger,
        icon: compliant ? Icons.check_circle_rounded : Icons.error_rounded,
      );

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: readableColor(context, color),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({required this.employee, this.radius = 24, super.key});

  final Employee employee;
  final double radius;

  static const _palette = [
    Color(0xFFFF6B00),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[employee.name.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        employee.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// Small chip showing one PPE item as worn / missing.
class PpeChip extends StatelessWidget {
  const PpeChip({required this.item, required this.ok, super.key});

  final PpeItem item;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.danger;
    return Tooltip(
      message: '${item.label}: ${ok ? 'detected' : 'missing'}',
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(item.icon, size: 18, color: color),
      ),
    );
  }
}

/// Circular progress with a big percentage in the middle.
class ComplianceRing extends StatelessWidget {
  const ComplianceRing({
    required this.value,
    this.size = 120,
    this.stroke = 12,
    this.color,
    this.caption,
    super.key,
  });

  final double? value;
  final double size;
  final double stroke;
  final Color? color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? complianceColor(value);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value ?? 0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: v,
                color: c,
                track: theme.colorScheme.outlineVariant,
                stroke: stroke,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value == null ? '–' : formatPercent(value!),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: size * 0.26,
                  height: 1,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(rect, 0, math.pi * 2, false, base..color = track)
      ..drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value.clamp(0, 1),
        false,
        base..color = color,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// A tidy KPI tile.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day bar chart of daily compliance (null = no scans that day).
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({required this.days, required this.values, super.key});

  final List<DateTime> days;
  final List<double?> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    values[i] == null ? '' : formatPercent(values[i]!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: values[i] ?? 0),
                    duration: Duration(milliseconds: 500 + i * 80),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      height: 8 + v * 84,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: values[i] == null
                            ? scheme.outlineVariant
                            : complianceColor(values[i]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekdayShort(days[i]),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: i == days.length - 1
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i == days.length - 1
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
