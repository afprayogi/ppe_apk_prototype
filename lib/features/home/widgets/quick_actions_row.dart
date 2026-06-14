import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onRegist;
  final VoidCallback onRanked;
  final VoidCallback onArchive;

  const QuickActionsRow({
    super.key,
    required this.onRegist,
    required this.onRanked,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ActionItem(
              icon: Icons.person_add_alt_1,
              label: 'Regist',
              color: AppColors.primaryGreen,
              onTap: onRegist,
            ),
            _ActionItem(
              icon: Icons.bar_chart_rounded,
              label: 'Ranked',
              color: AppColors.amber,
              onTap: onRanked,
            ),
            _ActionItem(
              icon: Icons.archive_outlined,
              label: 'Archive',
              color: Colors.blueAccent,
              onTap: onArchive,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Lainnya ..',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryGreen,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 30.sp, color: color),
          ),
          SizedBox(height: 6.h),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
