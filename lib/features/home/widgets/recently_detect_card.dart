import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/detection_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/section_header.dart';

class RecentlyDetectCard extends StatefulWidget {
  final List<DetectionRecord> records;
  final void Function(DetectionRecord)? onDetail;

  const RecentlyDetectCard({
    super.key,
    required this.records,
    this.onDetail,
  });

  @override
  State<RecentlyDetectCard> createState() => _RecentlyDetectCardState();
}

class _RecentlyDetectCardState extends State<RecentlyDetectCard> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final hasRecords = widget.records.isNotEmpty;
    final rec = hasRecords ? widget.records[_current] : null;

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GreenSectionChip(label: 'Recently Detect'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 130.h,
            child: Stack(
              children: [
                // Image / placeholder area
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: hasRecords
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                rec!.missingPpe.isEmpty
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                size: 40.sp,
                                color: rec.missingPpe.isEmpty
                                    ? AppColors.progressGreen
                                    : AppColors.progressAmber,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                rec.employeeName.split(' ').first,
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryGreen),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${rec.overallConfidence.toStringAsFixed(0)}%',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined,
                              size: 50, color: AppColors.primaryGreen),
                        ),
                ),
                // Left arrow
                if (hasRecords && widget.records.length > 1)
                  Positioned(
                    left: 4, top: 0, bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_left,
                        onTap: () {
                          if (_current > 0) setState(() => _current--);
                        },
                      ),
                    ),
                  ),
                // Right arrow
                if (hasRecords && widget.records.length > 1)
                  Positioned(
                    right: 4, top: 0, bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_right,
                        onTap: () {
                          if (_current < widget.records.length - 1) {
                            setState(() => _current++);
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          // Dot indicator
          if (hasRecords && widget.records.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  widget.records.length.clamp(0, 5),
                  (i) => Container(
                        width: i == _current ? 12.w : 5.w,
                        height: 5.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.primaryGreen
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      )),
            ),
          SizedBox(height: 6.h),
          // Detail button — now functional
          GestureDetector(
            onTap: rec != null ? () => widget.onDetail?.call(rec) : null,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Detail',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.black38),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
