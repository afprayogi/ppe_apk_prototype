import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PpeItemCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isRequired; // green dot = required, red dot = not required
  final VoidCallback onTap;

  const PpeItemCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isRequired,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80.w,
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceGreen : AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 32.sp, color: AppColors.primaryGreen),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRequired
                          ? AppColors.progressGreen
                          : AppColors.progressRed,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Mapping of PPE label -> icon
final Map<String, IconData> ppeIconMap = {
  'Gloves':      Icons.back_hand_outlined,
  'Vest':        Icons.checkroom,
  'Glass':       Icons.remove_red_eye_outlined,
  'goggles':     Icons.remove_red_eye_outlined,
  'Helmet':      Icons.engineering,
  'helmet':      Icons.engineering,
  'Mask':        Icons.masks_outlined,
  'mask':        Icons.masks_outlined,
  'Boots':       Icons.safety_divider,
  'safety_shoe': Icons.safety_divider,
  'Lock':        Icons.lock_outline,
};
