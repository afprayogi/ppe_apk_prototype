import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/detection_model.dart';
import '../../providers/detection_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ppe_item_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});
  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(detectionProvider.notifier).confirmSave();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppConstants.routeHome, (_) => false);
  }

  void _retry() {
    Navigator.pushReplacementNamed(context, AppConstants.routeScanner);
  }

  @override
  Widget build(BuildContext context) {
    final result     = ref.watch(lastResultProvider);
    final imageBytes = ref.watch(lastCapturedImageProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('VIVATPASS AI', style: AppTextStyles.headlineOnGreen),
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
      body: Stack(
        children: [
          // Background foto
          Positioned.fill(
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Container(color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.image_not_supported,
                          color: Colors.white38, size: 64))),
          ),

          // Gradient bawah
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.35, 1.0],
                ),
              ),
            ),
          ),

          // Date + confidence
          Positioned(
            top: 12, left: 14, right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DateBadge(),
                _ConfidenceBadge(confidence: result?.overallConfidence ?? 0.0),
              ],
            ),
          ),

          // RESULT AI label
          Positioned(
            bottom: 260, left: 0, right: 0,
            child: Center(
              child: Text('RESULT AI',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.white,
                  shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
                )),
            ),
          ),

          // Tombol Simpan & Ulangi
          Positioned(
            bottom: 200, left: 20, right: 20,
            child: Row(
              children: [
                // Ulangi Scan
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _retry,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text('Ulangi Scan',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Simpan
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? SizedBox(
                            width: 16.w, height: 16.w,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_alt, color: Colors.white),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Employee result card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _EmployeeResultCard(result: result),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          switch (i) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(
                  context, AppConstants.routeHome, (_) => false);
            case 1:
              Navigator.pushNamedAndRemoveUntil(
                  context, AppConstants.routeAbsensi, (_) => false);
            case 3: Navigator.pushNamed(context, AppConstants.routeTrain);
            case 4: Navigator.pushNamed(context, AppConstants.routeInfo);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _DateBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'Surabaya, ${DateFormat('dd - MM - yyyy').format(now)}',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.white, width: 1),
      ),
      child: Text(
        '${confidence.toStringAsFixed(0)}%',
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _EmployeeResultCard extends StatelessWidget {
  final DetectionRecord? result;

  const _EmployeeResultCard({this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.surfaceGreen,
                child: Icon(Icons.person,
                    color: AppColors.primaryGreen, size: 28.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name : ${result?.employeeName ?? 'ERIC DWI HARTAWA'}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white),
                    ),
                    Text(
                      'NIA  : ${result?.nia ?? '2036231023'}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // PPE icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: (result?.detectedPpe.isNotEmpty == true
                    ? result!.detectedPpe
                    : ['Helmet', 'Vest', 'Boots', 'Gloves'])
                .map((ppe) => Column(
                      children: [
                        Icon(
                          ppeIconMap[ppe] ?? Icons.shield_outlined,
                          color: AppColors.progressGreen,
                          size: 26.sp,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          ppe,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.white),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
