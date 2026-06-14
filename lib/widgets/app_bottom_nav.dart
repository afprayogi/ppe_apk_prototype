import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(index: 0, current: currentIndex, icon: Icons.home_filled,       label: 'Home',      onTap: onTap),
          _NavItem(index: 1, current: currentIndex, icon: Icons.bar_chart_rounded,  label: 'Statistic', onTap: onTap),
          _ScanButton(isCurrent: currentIndex == 2, onTap: () => onTap(2)),
          _NavItem(index: 3, current: currentIndex, icon: Icons.auto_fix_high,      label: 'Train',     onTap: onTap),
          _NavItem(index: 4, current: currentIndex, icon: Icons.info_outline,       label: 'Info',      onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int current;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: isActive ? AppColors.navActive : AppColors.navInactive,
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.navActive : AppColors.navInactive,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final bool isCurrent;
  final VoidCallback onTap;

  const _ScanButton({required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? AppColors.navActive : AppColors.white,
                border: Border.all(color: AppColors.darkGreen, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: isCurrent ? AppColors.darkGreen : AppColors.darkGreen,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
