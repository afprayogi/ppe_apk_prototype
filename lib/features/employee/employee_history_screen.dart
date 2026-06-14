import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/pdf_service.dart';
import '../../models/detection_model.dart';
import '../../models/employee_model.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ppe_item_card.dart';

class EmployeeHistoryScreen extends ConsumerWidget {
  final EmployeeModel employee;
  const EmployeeHistoryScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(detectionProvider);
    final records = state.records
        .where((r) => r.employeeId == employee.id)
        .toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    final total     = records.length;
    final compliant = records.where((r) => r.isComplete).length;
    final rate      = total == 0 ? 0.0 : compliant / total;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(employee.name.split(' ').first,
            style: AppTextStyles.headlineOnGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Export PDF',
            onPressed: records.isEmpty
                ? null
                : () => PdfService.instance
                    .exportEmployeeHistory(employee, records),
          ),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 12.h),
                  Text('Belum ada riwayat scan',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(14.r),
              children: [
                // ── Profil ─────────────────────────────────────────────────
                _ProfileCard(employee: employee),
                SizedBox(height: 12.h),

                // ── Statistik ──────────────────────────────────────────────
                _StatsRow(
                    total: total, compliant: compliant, rate: rate),
                SizedBox(height: 12.h),

                // ── Grafik kepatuhan 7 hari terakhir ───────────────────────
                if (records.length >= 3) ...[
                  _ComplianceChart(records: records),
                  SizedBox(height: 12.h),
                ],

                // ── APD paling sering kurang ────────────────────────────────
                _MissingPpeChart(records: records),
                SizedBox(height: 12.h),

                // ── Riwayat scan ───────────────────────────────────────────
                Text('Riwayat Scan (${records.length})',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 8.h),
                ...records.map((r) => _HistoryTile(record: r)),
                SizedBox(height: 80.h),
              ],
            ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final EmployeeModel employee;
  const _ProfileCard({required this.employee});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: AppColors.amber,
            backgroundImage: employee.avatarUrl != null &&
                    File(employee.avatarUrl!).existsSync()
                ? FileImage(File(employee.avatarUrl!))
                : null,
            child: employee.avatarUrl == null
                ? Icon(Icons.person, size: 32.sp, color: AppColors.darkGreen)
                : null,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: Colors.white)),
                Text('NIA: ${employee.nia}  •  ${employee.shift}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70)),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 4,
                  children: employee.requiredPpe.map((p) => Chip(
                    label: Text(p,
                        style: TextStyle(
                            fontSize: 9.sp, color: Colors.white)),
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int total, compliant;
  final double rate;
  const _StatsRow(
      {required this.total,
      required this.compliant,
      required this.rate});
  @override
  Widget build(BuildContext context) {
    final color = rate >= 0.8
        ? AppColors.progressGreen
        : rate >= 0.5
            ? Colors.orange
            : AppColors.progressRed;
    return Row(
      children: [
        _StatBox('Total Scan', '$total', AppColors.primaryGreen),
        SizedBox(width: 8.w),
        _StatBox('Lengkap', '$compliant', AppColors.progressGreen),
        SizedBox(width: 8.w),
        _StatBox('Tidak Lengkap', '${total - compliant}',
            AppColors.progressRed),
        SizedBox(width: 8.w),
        _StatBox('Kepatuhan',
            '${(rate * 100).toInt()}%', color),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headlineMedium
                    .copyWith(color: color, fontWeight: FontWeight.w800)),
            Text(label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall
                    .copyWith(color: color, fontSize: 9.sp)),
          ],
        ),
      ),
    );
  }
}

// ── Compliance Chart (7 hari terakhir) ───────────────────────────────────────
class _ComplianceChart extends StatelessWidget {
  final List<DetectionRecord> records;
  const _ComplianceChart({required this.records});

  @override
  Widget build(BuildContext context) {
    // Ambil 7 hari terakhir
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int d = 6; d >= 0; d--) {
      final day = DateTime(now.year, now.month, now.day - d);
      final dayRecs = records.where((r) =>
          r.detectedAt.year == day.year &&
          r.detectedAt.month == day.month &&
          r.detectedAt.day == day.day);
      final total = dayRecs.length;
      final rate  = total == 0
          ? 0.0
          : dayRecs.where((r) => r.isComplete).length / total * 100;
      spots.add(FlSpot((6 - d).toDouble(), rate));
    }

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kepatuhan 7 Hari Terakhir',
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 12.h),
          SizedBox(
            height: 120.h,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final day = DateTime.now()
                          .subtract(Duration(days: 6 - v.toInt()));
                      return Text(DateFormat('dd/M').format(day),
                          style: TextStyle(fontSize: 8.sp));
                    },
                    interval: 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0, maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primaryGreen,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

// ── Missing PPE Frequency ─────────────────────────────────────────────────────
class _MissingPpeChart extends StatelessWidget {
  final List<DetectionRecord> records;
  const _MissingPpeChart({required this.records});

  @override
  Widget build(BuildContext context) {
    final freq = <String, int>{};
    for (final r in records) {
      for (final p in r.missingPpe) {
        freq[p] = (freq[p] ?? 0) + 1;
      }
    }
    if (freq.isEmpty) return const SizedBox.shrink();

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value.toDouble();

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APD Paling Sering Kurang',
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.progressRed,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 10.h),
          ...sorted.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Icon(ppeIconMap[e.key] ?? Icons.shield_outlined,
                        size: 16.sp,
                        color: AppColors.progressRed),
                    SizedBox(width: 8.w),
                    SizedBox(
                        width: 60.w,
                        child: Text(e.key,
                            style: AppTextStyles.bodyMedium)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: e.value / max,
                          minHeight: 8.h,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                              AppColors.progressRed),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text('${e.value}×',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.progressRed,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── History Tile ──────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final DetectionRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final ok = record.isComplete;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
            color: ok
                ? AppColors.progressGreen.withValues(alpha: 0.3)
                : AppColors.progressRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: ok ? AppColors.progressGreen : AppColors.progressRed,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy  HH:mm')
                      .format(record.detectedAt),
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.grey),
                ),
                SizedBox(height: 3.h),
                if (record.detectedPpe.isNotEmpty)
                  Text('✓ ${record.detectedPpe.join(", ")}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.progressGreen, fontSize: 10.sp)),
                if (record.missingPpe.isNotEmpty)
                  Text('✗ Kurang: ${record.missingPpe.join(", ")}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.progressRed, fontSize: 10.sp)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color:
                      (ok ? AppColors.progressGreen : AppColors.progressRed)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  ok ? 'LENGKAP' : 'KURANG',
                  style: AppTextStyles.labelSmall.copyWith(
                    color:
                        ok ? AppColors.progressGreen : AppColors.progressRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${record.overallConfidence.toStringAsFixed(0)}%',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
