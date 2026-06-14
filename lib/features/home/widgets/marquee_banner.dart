import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../constants/app_constants.dart';

class MarqueeBanner extends StatefulWidget {
  const MarqueeBanner({super.key});

  @override
  State<MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<MarqueeBanner>
    with SingleTickerProviderStateMixin {
  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final next = (_page + 1) % AppConstants.safetyMessages.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _page = next);
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 40.h,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: PageView.builder(
            controller: _ctrl,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppConstants.safetyMessages.length,
            itemBuilder: (_, i) => Center(
              child: Text(
                AppConstants.safetyMessages[i],
                style: AppTextStyles.labelLarge.copyWith(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            AppConstants.safetyMessages.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == _page ? 16.w : 6.w,
              height: 6.h,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: i == _page ? AppColors.primaryGreen : AppColors.divider,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
