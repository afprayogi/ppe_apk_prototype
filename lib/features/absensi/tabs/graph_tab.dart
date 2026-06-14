import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/detection_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class GraphTab extends ConsumerWidget {
  const GraphTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state           = ref.watch(detectionProvider);
    final trend           = ref.watch(trendDataProvider);
    final ppeStatsAsync   = ref.watch(missingPpeStatsProvider);
    final completionAsync = ref.watch(completionStatsProvider);
    final todayStr        = DateFormat('dd-MM-yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: EdgeInsets.all(14.r),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Non-Safety',
                  value: state.nonSafetyCount.toString(),
                  subtitle: 'Hari ini',
                  bg: AppColors.white,
                  valueColor: AppColors.progressAmber,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatCard(
                  label: 'Total Scan',
                  value: state.totalPersonCount.toString(),
                  subtitle: todayStr,
                  bg: AppColors.primaryGreen,
                  labelColor: AppColors.white,
                  valueColor: AppColors.white,
                  subtitleColor: AppColors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Trend bar chart (10 hari terakhir dari DB)
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tren Deteksi 10 Hari',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primaryGreen)),
                SizedBox(height: 10.h),
                SizedBox(
                  height: 160.h,
                  child: trend.isEmpty
                      ? Center(
                          child: Text('Belum ada data',
                              style: AppTextStyles.bodyMedium))
                      : BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.divider,
                                strokeWidth: 0.8,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32.w,
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) => Text(
                                    'H-${trend.length - v.toInt()}',
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            barGroups: List.generate(
                              trend.length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: trend[i],
                                    width: 14.w,
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Pie charts row — data dari DB
          Row(
            children: [
              Expanded(
                child: ppeStatsAsync.when(
                  loading: () => _PieCardLoading(title: 'APD Tidak Lengkap'),
                  error: (_, __) => _PieCardLoading(title: 'APD Tidak Lengkap'),
                  data: (stats) => _PpeMissingPieCard(stats: stats),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: completionAsync.when(
                  loading: () => _PieCardLoading(title: 'Status Scan'),
                  error: (_, __) => _PieCardLoading(title: 'Status Scan'),
                  data: (stats) => _CompletionPieCard(stats: stats),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, subtitle;
  final Color bg;
  final Color? labelColor, valueColor, subtitleColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.bg,
    this.labelColor,
    this.valueColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: labelColor ?? AppColors.textSecondary)),
          Text(value,
              style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 36.sp, color: valueColor ?? AppColors.gold)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: (subtitleColor ?? AppColors.textSecondary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                    color: subtitleColor ?? AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Loading placeholder ───────────────────────────────────────────────────────
class _PieCardLoading extends StatelessWidget {
  final String title;
  const _PieCardLoading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(title,
              style: AppTextStyles.labelSmall
                  .copyWith(fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          SizedBox(
            height: 100.h,
            child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }
}

// ── PPE Missing Pie Chart (dari DB) ──────────────────────────────────────────
class _PpeMissingPieCard extends StatelessWidget {
  final Map<String, int> stats;
  const _PpeMissingPieCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primaryGreen, AppColors.amber, Colors.black87,
      Colors.lightGreen, AppColors.darkGreen, AppColors.progressRed,
    ];
    final total = stats.values.fold(0, (a, b) => a + b);

    final sections = stats.isEmpty
        ? [
            PieChartSectionData(
                value: 1, color: AppColors.divider,
                title: 'Belum ada', radius: 40.r,
                titleStyle: AppTextStyles.labelSmall)
          ]
        : stats.entries.toList().asMap().entries.map((e) {
            final idx  = e.key;
            final name = e.value.key;
            final cnt  = e.value.value;
            final pct  = total > 0 ? (cnt / total * 100) : 0.0;
            return PieChartSectionData(
              value: cnt.toDouble(),
              color: colors[idx % colors.length],
              title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
              radius: 40.r,
              titleStyle: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.white, fontSize: 8.sp),
              badgeWidget: pct < 10
                  ? null
                  : null,
            );
          }).toList();

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('APD Sering Hilang',
                style: AppTextStyles.labelSmall
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 100.h,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 18.r,
              sectionsSpace: 2,
            )),
          ),
          SizedBox(height: 6.h),
          // Legend
          if (stats.isNotEmpty)
            Wrap(
              spacing: 4.w,
              runSpacing: 2.h,
              children: stats.entries.toList().asMap().entries.map((e) {
                final idx  = e.key;
                final name = e.value.key;
                final cnt  = e.value.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w, height: 8.w,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[idx % colors.length]),
                    ),
                    SizedBox(width: 3.w),
                    Text('$name($cnt)',
                        style: AppTextStyles.labelSmall
                            .copyWith(fontSize: 8.sp)),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Completion Pie Chart (dari DB) ───────────────────────────────────────────
class _CompletionPieCard extends StatelessWidget {
  final Map<String, int> stats;
  const _CompletionPieCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final complete   = (stats['complete']   ?? 0).toDouble();
    final incomplete = (stats['incomplete'] ?? 0).toDouble();
    final total      = complete + incomplete;

    final pctComplete = total > 0 ? (complete / total * 100) : 0.0;

    final sections = total == 0
        ? [
            PieChartSectionData(
                value: 1, color: AppColors.divider,
                title: 'Belum ada', radius: 40.r,
                titleStyle: AppTextStyles.labelSmall)
          ]
        : [
            PieChartSectionData(
              value: complete,
              color: AppColors.progressGreen,
              title: '${pctComplete.toStringAsFixed(1)}%',
              radius: 40.r,
              titleStyle: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.white, fontSize: 9.sp),
            ),
            PieChartSectionData(
              value: incomplete,
              color: AppColors.progressAmber,
              title: '',
              radius: 40.r,
            ),
          ];

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Status APD Lengkap',
                style: AppTextStyles.labelSmall
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 100.h,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 18.r,
              sectionsSpace: 2,
            )),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Leg(color: AppColors.progressGreen, label: 'Lengkap'),
              SizedBox(width: 8.w),
              _Leg(color: AppColors.progressAmber, label: 'Tidak'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color;
  final String label;
  const _Leg({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        SizedBox(width: 3.w),
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9.sp)),
      ],
    );
  }
}
