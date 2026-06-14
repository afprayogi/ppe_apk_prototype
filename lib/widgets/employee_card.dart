import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/detection_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmployeeDetectionCard extends StatelessWidget {
  final DetectionRecord record;
  final VoidCallback? onTap;

  const EmployeeDetectionCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = record.status == DetectionStatus.complete;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceGreen,
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: ClipOval(
                child: Icon(
                  Icons.person,
                  size: 32.sp,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      children: [
                        const TextSpan(
                            text: 'Nama  : ',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: record.employeeName),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      children: [
                        const TextSpan(
                            text: 'NIA    : ',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: record.nia),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Next scan on day : ${record.nextScanFormatted}',
                    style:
                        AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 6.h),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? AppColors.progressGreen
                          : AppColors.progressAmber,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      isComplete ? 'APD Lengkap' : 'APD Tidak Lengkap',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
}
