import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ppe_item_card.dart';

class RankScreen extends HookConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<String>('ALL');
    final rankAsync = ref.watch(rankDataProvider(selected.value));
    final state     = ref.watch(detectionProvider);

    final filterItems = ['ALL', 'Vest', 'Gloves', 'Glass', 'Helmet', 'Boots'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Rank', style: AppTextStyles.headlineOnGreen),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.amber,
              child: Icon(Icons.person, color: AppColors.darkGreen, size: 20.sp),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14.r),
        child: Column(
          children: [
            // Total capture card
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text('Total Capture Non-Safety Hari Ini',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white)),
                  SizedBox(height: 4.h),
                  Text(
                    _formatCount(state.nonSafetyCount),
                    style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.white, fontSize: 28.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Filter label
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryGreen),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text('Filter',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.primaryGreen)),
              ),
            ),
            SizedBox(height: 10.h),

            // Filter chips (scrollable row)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterItems.map((item) {
                  final isActive = selected.value == item;
                  return GestureDetector(
                    onTap: () => selected.value = item,
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 40.w, height: 40.w,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryGreen
                            : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGreen),
                      ),
                      child: Center(
                        child: item == 'ALL'
                            ? Text('ALL',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: isActive
                                        ? AppColors.white
                                        : AppColors.primaryGreen,
                                    fontSize: 9.sp))
                            : Icon(
                                ppeIconMap[item] ?? Icons.shield_outlined,
                                size: 18.sp,
                                color: isActive
                                    ? AppColors.white
                                    : AppColors.primaryGreen,
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 14.h),

            // Rank list from DB
            Container(
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
                    child: Text(
                      'Top Person not use '
                      '${selected.value == 'ALL' ? 'APD' : selected.value}',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  rankAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryGreen)),
                    error: (_, __) => Text('Gagal memuat data',
                        style: AppTextStyles.bodyMedium),
                    data: (list) => list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.r),
                              child: Text('Belum ada data deteksi',
                                  style: AppTextStyles.bodyMedium),
                            ),
                          )
                        : Column(
                            children: list.asMap().entries.map((e) {
                              final rank  = e.key + 1;
                              final row   = e.value;
                              return _RankItem(
                                rank:  rank,
                                name:  row['employee_name'] as String,
                                nia:   row['nia'] as String,
                                score: row['score'] as int,
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} jt';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}.000';
    return n.toString();
  }
}

class _RankItem extends StatelessWidget {
  final int rank;
  final String name;
  final String nia;
  final int score;

  const _RankItem({
    required this.rank,
    required this.name,
    required this.nia,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final medalColors = [AppColors.gold, Colors.grey.shade400, const Color(0xFFCD7F32)];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.surfaceGreen : AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
            color: isTop3 ? AppColors.primaryGreen : AppColors.divider),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28.w, height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop3
                  ? medalColors[rank - 1]
                  : AppColors.primaryGreen,
            ),
            child: Center(
              child: Text('$rank',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            radius: 14.r,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
            child: Icon(Icons.person, size: 16.sp,
                color: AppColors.primaryGreen),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
                Text(nia,  style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Text('$score x',
              style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.progressRed, fontSize: 12.sp)),
        ],
      ),
    );
  }
}
